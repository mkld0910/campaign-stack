# Branch Migration Notice

## Important: `master` is now the default branch

The Campaign Stack repository has consolidated to use **`master`** as the primary branch.

### For Users Cloning the Repository

The repository now automatically uses the `master` branch:

```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
# You're now on the master branch with all the latest updates
```

### For Existing Users

If you previously cloned this repository, update your local copy:

```bash
cd /srv/campaign-stack
git fetch origin
git checkout master
git pull origin master
```

### Branch History

- **`main` branch** - Original branch, now outdated
- **`master` branch** - Current branch with all fixes and features

The `main` branch will be removed in a future update after all users have migrated.

### Why the Change?

During development, updates were accidentally pushed to different branches, causing:
- Confusion about which branch had the latest code
- Missing files when users cloned from `main`
- Duplicate scripts in wrong locations

All issues have been resolved, and `master` now contains:
- ✅ Complete file structure
- ✅ All latest fixes and features
- ✅ Organized directory layout
- ✅ Web-based GUI installer
- ✅ Updated documentation

### Need Help?

If you encounter any issues after switching branches:

1. Check you're on master: `git branch`
2. View recent updates: `git log --oneline -5`
3. Report issues: [GitHub Issues](https://github.com/mkld0910/campaign-stack/issues)

---

**Last Updated:** November 2024
**Status:** Active Migration
