#!/bin/bash
# Sync Plane data with git repository
# Usage: ./sync-plane.sh [export|import|pull]
#
# export - Export Plane issues to JSON (for commit)
# import - Import issues from JSON to Plane (after git pull)
# pull   - Git pull + import (shortcut for team sync)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_DIR="$SCRIPT_DIR/exports"
API_KEY="plane_api_efb329a1bef9492995648b9ee92e939a"
BASE_URL="http://localhost:8088/api/v1"
WORKSPACE="fug"
PROJECT_ID="f110c685-ede4-4756-8e41-8cb39bb316f3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✔${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✘${NC} $1"; }

# Ensure export directory exists
mkdir -p "$EXPORT_DIR"

# ============================================
# Export Functions
# ============================================

export_issues() {
    log_info "Exporting Plane issues..."

    # Get all issues and save to file
    curl -s "$BASE_URL/workspaces/$WORKSPACE/projects/$PROJECT_ID/issues/" \
        -H "x-api-key: $API_KEY" > "$EXPORT_DIR/issues-raw.json"

    # Parse and format issues
    python3 - << 'PYTHON_SCRIPT'
import json
import os

export_dir = os.environ.get('EXPORT_DIR', 'exports')

try:
    with open(os.path.join(export_dir, 'issues-raw.json'), 'r') as f:
        data = json.load(f)

    # Handle both list and paginated response
    if isinstance(data, dict) and 'results' in data:
        issues = data['results']
    elif isinstance(data, list):
        issues = data
    else:
        issues = []

    # Format issues for readability
    formatted_issues = []
    for issue in issues:
        formatted = {
            'id': issue.get('id'),
            'name': issue.get('name'),
            'description': issue.get('description_html', ''),
            'priority': issue.get('priority'),
            'state': issue.get('state'),
            'parent': issue.get('parent'),
            'created_at': issue.get('created_at'),
            'updated_at': issue.get('updated_at'),
            'sequence_id': issue.get('sequence_id'),
        }
        formatted_issues.append(formatted)

    # Sort by sequence_id for consistent ordering
    formatted_issues.sort(key=lambda x: x.get('sequence_id', 0))

    # Save formatted JSON
    output_path = os.path.join(export_dir, 'issues.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(formatted_issues, f, indent=2, ensure_ascii=False)

    print(f"Exported {len(formatted_issues)} issues")

except Exception as e:
    print(f"Error: {e}")
    exit(1)
PYTHON_SCRIPT

    log_success "Issues exported to $EXPORT_DIR/issues.json"
}

export_states() {
    log_info "Exporting Plane states..."

    curl -s "$BASE_URL/workspaces/$WORKSPACE/projects/$PROJECT_ID/states/" \
        -H "x-api-key: $API_KEY" > "$EXPORT_DIR/states.json"

    log_success "States exported to $EXPORT_DIR/states.json"
}

export_labels() {
    log_info "Exporting Plane labels..."

    curl -s "$BASE_URL/workspaces/$WORKSPACE/projects/$PROJECT_ID/labels/" \
        -H "x-api-key: $API_KEY" > "$EXPORT_DIR/labels.json"

    log_success "Labels exported to $EXPORT_DIR/labels.json"
}

create_summary() {
    log_info "Creating human-readable summary..."

    python3 - << 'PYTHON_SCRIPT'
import json
import os

export_dir = os.environ.get('EXPORT_DIR', 'exports')

try:
    # Load issues
    with open(os.path.join(export_dir, 'issues.json'), 'r') as f:
        issues = json.load(f)

    # Load states for name mapping
    states_map = {}
    try:
        with open(os.path.join(export_dir, 'states.json'), 'r') as f:
            states_data = json.load(f)
            states = states_data if isinstance(states_data, list) else states_data.get('results', [])
            for state in states:
                states_map[state['id']] = state['name']
    except:
        pass

    # Generate markdown summary
    summary = "# Plane Issues Summary\n\n"
    summary += f"> Auto-generated export - {len(issues)} issues\n"
    summary += "> Run `./sync-plane.sh export` to update\n\n"

    # Group by parent (epics vs stories)
    epics = [i for i in issues if not i.get('parent')]

    for epic in epics:
        priority = epic.get('priority', 'none')
        state_name = states_map.get(epic.get('state'), 'Unknown')
        checkbox = "x" if state_name == "Done" else " "
        summary += f"## [{checkbox}] [{priority.upper()}] {epic['name']}\n"
        summary += f"**State:** {state_name}\n\n"

        # Find children
        children = [i for i in issues if i.get('parent') == epic['id']]
        if children:
            for child in children:
                child_state = states_map.get(child.get('state'), '?')
                checkbox = "x" if child_state == "Done" else " "
                summary += f"- [{checkbox}] {child['name']} ({child_state})\n"
            summary += "\n"

    # Save summary
    with open(os.path.join(export_dir, 'ISSUES.md'), 'w', encoding='utf-8') as f:
        f.write(summary)

    print("Created ISSUES.md summary")

except Exception as e:
    print(f"Warning: Could not create summary: {e}")
PYTHON_SCRIPT
}

export_all() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Plane Export${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    echo ""

    export EXPORT_DIR="$EXPORT_DIR"

    export_states
    export_labels
    export_issues
    create_summary

    # Remove raw file (keep only formatted)
    rm -f "$EXPORT_DIR/issues-raw.json"

    echo ""
    log_success "Export complete! Files in: $EXPORT_DIR"
    echo ""
    echo "To commit:"
    echo "  git add infrastructure/plane/exports/"
    echo "  git commit -m 'chore(plane): sync Plane issues'"
}

# ============================================
# Import Functions
# ============================================

import_issues() {
    log_info "Importing Plane issues from export..."

    if [ ! -f "$EXPORT_DIR/issues.json" ]; then
        log_error "No export file found: $EXPORT_DIR/issues.json"
        log_info "Run './sync-plane.sh export' first or git pull to get exports"
        exit 1
    fi

    export EXPORT_DIR="$EXPORT_DIR"
    export BASE_URL="$BASE_URL"
    export WORKSPACE="$WORKSPACE"
    export PROJECT_ID="$PROJECT_ID"
    export API_KEY="$API_KEY"

    python3 - << 'PYTHON_SCRIPT'
import json
import os
import urllib.request
import urllib.error

export_dir = os.environ['EXPORT_DIR']
base_url = os.environ['BASE_URL']
workspace = os.environ['WORKSPACE']
project_id = os.environ['PROJECT_ID']
api_key = os.environ['API_KEY']

def api_request(method, endpoint, data=None):
    url = f"{base_url}/workspaces/{workspace}/projects/{project_id}/{endpoint}"
    headers = {
        'x-api-key': api_key,
        'Content-Type': 'application/json'
    }

    if data:
        data = json.dumps(data).encode('utf-8')

    req = urllib.request.Request(url, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return {'error': str(e), 'code': e.code}

def get_existing_issues():
    result = api_request('GET', 'issues/')
    if isinstance(result, dict) and 'results' in result:
        return {i['name']: i for i in result['results']}
    elif isinstance(result, list):
        return {i['name']: i for i in result}
    return {}

try:
    with open(os.path.join(export_dir, 'issues.json'), 'r') as f:
        issues = json.load(f)

    existing = get_existing_issues()
    created = 0
    skipped = 0

    # First pass: create issues without parents
    id_mapping = {}

    for issue in issues:
        if issue['name'] in existing:
            id_mapping[issue['id']] = existing[issue['name']]['id']
            skipped += 1
            continue

        if issue.get('parent'):
            continue

        data = {
            'name': issue['name'],
            'description_html': issue.get('description', ''),
            'priority': issue.get('priority', 'none'),
            'state': issue.get('state'),
        }

        result = api_request('POST', 'issues/', data)
        if 'error' not in result:
            id_mapping[issue['id']] = result['id']
            created += 1
            print(f"  Created: {issue['name']}")

    # Second pass: create child issues
    for issue in issues:
        if issue['name'] in existing:
            continue

        if not issue.get('parent'):
            continue

        parent_id = id_mapping.get(issue['parent'])
        if not parent_id:
            continue

        data = {
            'name': issue['name'],
            'description_html': issue.get('description', ''),
            'priority': issue.get('priority', 'none'),
            'state': issue.get('state'),
            'parent': parent_id,
        }

        result = api_request('POST', 'issues/', data)
        if 'error' not in result:
            created += 1
            print(f"  Created: {issue['name']}")

    print(f"\nImport complete: {created} created, {skipped} already existed")

except Exception as e:
    print(f"Error: {e}")
    exit(1)
PYTHON_SCRIPT

    log_success "Import complete"
}

# ============================================
# Pull & Sync
# ============================================

pull_and_sync() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Plane Pull & Sync${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Pulling latest exports from git..."

    cd "$(git rev-parse --show-toplevel)"
    git fetch origin
    git checkout origin/develop -- infrastructure/plane/exports/ 2>/dev/null || {
        log_warn "No remote exports found, skipping git pull"
    }

    import_issues

    log_success "Sync complete!"
}

# ============================================
# Main
# ============================================

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  export  - Export Plane issues to JSON files (then commit)"
    echo "  import  - Import issues from JSON files to Plane"
    echo "  pull    - Git pull exports + import to Plane"
    echo "  help    - Show this help"
    echo ""
    echo "Workflow for teams:"
    echo "  1. Developer A makes changes in Plane"
    echo "  2. Developer A runs: ./sync-plane.sh export && git add . && git commit && git push"
    echo "  3. Developer B runs: ./sync-plane.sh pull"
}

case "${1:-help}" in
    export)
        export_all
        ;;
    import)
        import_issues
        ;;
    pull)
        pull_and_sync
        ;;
    *)
        show_usage
        ;;
esac
