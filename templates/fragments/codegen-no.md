4. **Install dependencies before gating the merge.** A merge does not install anything. If either side added a dependency, the first gate command fails on it and reads as a code error. Install first, on both the branch and `{{MAIN_BRANCH}}`, then gate.

