#!/bin/bash
# Set Branch Protection for governed mode
# Run this AFTER the first push to main
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [ -z "$REPO" ]; then echo 'ERROR: run from inside a git repo with gh auth'; exit 1; fi
echo "Setting Branch Protection for $REPO..."
gh api -X PUT "repos/$REPO/branches/main/protection" --input - <<'EOF'
{
  "required_status_checks": {"strict": false, "contexts": ["governance-gate"]},
  "enforce_admins": false,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
echo "Done: PR-only merge, TheWorld governance gate required"
echo ""
echo "NOTE: enforce_admins=false — Admin can bypass Branch Protection (direct push)."
echo "  This allows GITHUB_TOKEN (Actions bot) to auto-merge approved PRs."
echo "  Required status check (governance-gate) still blocks PR merge without approval."
echo "  Ideal fix: GitHub App with merge-only permission (future)."
