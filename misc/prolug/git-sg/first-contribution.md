# Making your first Contribution 



1. Set up SSH authentication

2. Fork repo to your GH account

3. Clone repo to your local maching

4. Create branch
   ```bash
   git switch -c
   ```

5. Make edits

6. Stage your changes

7. Commit your changes

8. Push your commits

9. Open a pr

10. Wait for PR to get merged

11. Once your commits are merged, update your local fork
    - Create new remote for upstream

12. Push the local updated changes to your fork on GitHub

---


Add remote:
```bash
git remote add upstream https://github.com/ProfessionalLinuxUsersGroup/GitPracticeRepo.git
```

---


Recap:
```bash
git clone git@github.com:yourname/yourfork.git
git switch -c new-branch
vi somefile # make edits
git add somefile # stage changes
git commit -m "Descriptive message"
git push origin new-branch  # Push to your fork on your new branch

# Open PR
# PR gets merged

# Add original repo as a remote source
git remote add upstream https://github.com/original-place/original-repo.git

# Pull from the updated original
git pull upstream main
# Now your local clone is up to date and you gucci
```


