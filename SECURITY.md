# 🔒 Security Policy

## 🛡️ Repository Security Hardening

This repository has been hardened against public attacks with multiple layers of security:

### 1. Claude AI Integration Security

**Only `wscoble` can trigger Claude AI actions**. All Claude workflows have multiple security checks:

#### claude.yml (Manual Claude Invocation)
- **Primary check**: `github.actor == 'wscoble'` in workflow `if` condition
- **Secondary check**: Explicit bash verification of authorized user
- **Permissions**: Limited to only necessary permissions (contents, pull-requests, issues, actions)
- **Trigger**: Only responds to `@claude` mentions from `wscoble`

#### claude-code-review.yml (Automated PR Review)
- **Primary check**: PR author must be `wscoble` OR workflow actor must be `wscoble`
- **Secondary check**: Runtime verification of authorized users
- **Permissions**: Read-only except for PR comments
- **Scope**: Limited to specific file patterns if configured

### 2. GitHub Repository Settings

The following security settings are enforced:

#### General Security
- ✅ **Wiki disabled**: Prevents unmoderated public content
- ✅ **Projects disabled**: Reduces attack surface
- ✅ **Delete branch on merge**: Automatic cleanup
- ✅ **Rebase merge disabled**: Maintains clean history
- ✅ **Secret scanning enabled**: Prevents credential leaks
- ✅ **Secret scanning push protection enabled**: Blocks pushes with secrets

#### Branch Protection (main branch)
- ✅ **Required status checks**: CI must pass (`check`, `build-matrix`)
- ✅ **Strict status checks**: Branch must be up to date
- ✅ **Dismiss stale reviews**: Reviews dismissed on new pushes
- ✅ **Require conversation resolution**: All comments must be resolved
- ✅ **No force pushes**: Prevents history rewriting
- ✅ **No deletions**: Branch cannot be deleted

### 3. Workflow Security Best Practices

#### Fork Security
While GitHub doesn't allow disabling fork actions on personal repos, our workflows are protected by:
- User authentication checks (`github.actor == 'wscoble'`)
- No workflow runs from fork PRs without wscoble's involvement
- Secrets are never exposed to fork workflows

#### Token Security
- `CLAUDE_CODE_OAUTH_TOKEN` is stored as a repository secret
- Token is only accessible to authorized workflows
- API consumption is limited to wscoble's actions only

### 4. Attack Scenarios Mitigated

#### ❌ Public PR Spam Attack
**Scenario**: Malicious users open PRs to trigger Claude and consume API tokens
**Protection**:
- Claude review only runs for PRs from `wscoble`
- Manual Claude triggers require `wscoble` as actor
- Branch protection prevents unauthorized merges

#### ❌ Issue Comment Abuse
**Scenario**: Public users comment `@claude` to trigger actions
**Protection**:
- Workflow checks `github.actor == 'wscoble'`
- Secondary bash verification of user identity
- Non-wscoble mentions are ignored

#### ❌ Fork Workflow Abuse
**Scenario**: Forks try to run workflows with repository secrets
**Protection**:
- GitHub never exposes secrets to fork workflows
- User authentication prevents fork workflow execution
- All Claude triggers require wscoble authentication

#### ❌ Malicious Code Injection
**Scenario**: Users try to inject malicious code via PRs
**Protection**:
- Required status checks must pass
- Claude review is limited to wscoble's PRs
- Branch protection prevents direct pushes

### 5. Monitoring and Auditing

All security events are logged:
- GitHub Actions logs show all workflow runs
- Failed authentication attempts are logged
- All Claude interactions are tracked in Actions history
- Secret scanning alerts are sent to repository owner

### 6. Security Incident Response

If you suspect a security issue:

1. **Immediate Actions**:
   - Revoke `CLAUDE_CODE_OAUTH_TOKEN` in GitHub settings
   - Review recent Actions logs for unauthorized attempts
   - Check for any unexpected commits or PRs

2. **Contact**:
   - Repository owner: @wscoble
   - Report security issues privately (do not open public issues)

3. **Recovery**:
   - Regenerate all secrets
   - Review and update workflow permissions
   - Audit recent repository activity

### 7. Security Maintenance

Regular security tasks:
- [ ] Monthly review of Actions logs
- [ ] Quarterly secret rotation
- [ ] Review workflow permissions after any changes
- [ ] Monitor GitHub security advisories
- [ ] Keep workflows updated to latest action versions

## 🔐 Secrets Management

Required secrets for this repository:
- `CLAUDE_CODE_OAUTH_TOKEN`: OAuth token for Claude AI integration

## 📝 Security Checklist for Contributors

Before merging any PR that modifies workflows:
- [ ] Verify user authentication checks are in place
- [ ] Confirm permissions are minimal necessary
- [ ] Test that unauthorized users cannot trigger actions
- [ ] Review any new secret usage
- [ ] Ensure no secrets are logged or exposed

## 🚨 Reporting Security Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Contact @wscoble directly via GitHub
2. Provide detailed description of the vulnerability
3. Include steps to reproduce if applicable
4. Allow time for patch before public disclosure

---

**Last Security Audit**: December 2024
**Next Scheduled Audit**: March 2025
**Security Contact**: @wscoble