# GitHub Repository Setup Instructions

## Make `master` the Default Branch

To complete the repository cleanup, you need to make `master` the default branch on GitHub:

### Steps:

1. **Go to your GitHub repository**
   - Visit: https://github.com/mkld0910/campaign-stack

2. **Access Settings**
   - Click the "Settings" tab (top right)

3. **Navigate to Branches**
   - In the left sidebar, click "Branches"

4. **Change Default Branch**
   - Under "Default branch", you'll see the current default (probably `main`)
   - Click the switch/pencil icon next to it
   - Select `master` from the dropdown
   - Click "Update" or "I understand, update the default branch"

5. **Confirm the Change**
   - GitHub will ask you to confirm
   - Click "I understand, update the default branch"

6. **Optional: Delete the `main` Branch**
   - After confirming all users have migrated (wait a week or two)
   - Go to "Branches" in settings
   - Find the `main` branch in the list
   - Click the trash icon to delete it
   - This prevents future confusion

### What This Does:

- ✅ New users cloning the repository will get `master` branch by default
- ✅ GitHub will show `master` as the main branch in the web interface
- ✅ Pull requests and issues will default to `master`
- ✅ Documentation links will work correctly

### Verification:

After making the change, clone the repository in a new location to verify:

```bash
cd /tmp
git clone https://github.com/mkld0910/campaign-stack.git test-clone
cd test-clone
git branch
# Should show: * master
```

If you see `* master`, the setup is complete!

---

## Additional Cleanup (Optional)

### Add Branch Protection Rules

To prevent accidental changes to `master`:

1. Go to Settings → Branches
2. Click "Add rule" under "Branch protection rules"
3. Branch name pattern: `master`
4. Enable:
   - ✅ Require pull request reviews before merging (if working with others)
   - ✅ Require status checks to pass (if you set up CI/CD)
5. Click "Create" or "Save changes"

### Update Repository Topics/Tags

1. Go to main repository page
2. Click the gear icon next to "About"
3. Add topics: `docker`, `wordpress`, `civicrm`, `political-campaigns`, `vps`
4. Add description: "Complete political campaign infrastructure - WordPress, CiviCRM, automated backups. Deploy in 30 minutes."
5. Click "Save changes"

---

**Questions?**

If you run into issues, create an issue on GitHub or check the documentation.
