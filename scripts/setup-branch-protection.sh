#!/bin/bash
# Set Branch Protection for governed mode
# Run this AFTER the first push to main
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ -z "$REPO" ]; then echo 'ERROR: run from inside a git repo with gh auth'; exit 1; fi
echo "Setting Branch Protection for $REPO..."
gh api -X PUT "repos/$REPO/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": {"strict": false, "contexts": ["governance-gate"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 1},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
echo "Done: PR-only merge, TheWorld governance gate required, admin cannot bypass"
echo ""
echo "NOTE: enforce_admins=true — Admin CANNOT bypass Branch Protection."
echo "  Claude (via TheWorld canister) must approve PRs using:"
echo "    etherclaw review approve --pr <N>"
echo "  This enforces the demo governance flow where AI agent is the reviewer."
