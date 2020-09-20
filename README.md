# README.md

Publishing the Apache Flume web site requires:

1. Clone this repository into a local directory.
2. Checking out the asf-staging branch.
3. Performing any updates that are required.
4. In the root directory run `mvn package`.
5. Open your browser to point to *local directory*/target/site/index.html and review the site.
6. When the changes look ok run 'mvn resources:copy-resources@install'.
7. Perform `git add` on the affected files and `git commit'.
8. Perform git push.
9. After a few minutes review https://flume.staged.apache.org and make sure the appropriate changes are present.
10. Once the site has been approved checkout the asf-site branch. 
11. Perform `git rebase asf-staging` followed by `git push`.
12. After a few minutes verify that https://flume.apache.org has the correct changes.

Further information regarding what to edit in the site during a release may be found at 
[How to Release - Update the Web Site](https://cwiki.apache.org/confluence/display/FLUME/How+to+Release#HowtoRelease-Updatethewebsite).
