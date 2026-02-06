# Contributing

## Workflow

1. Fork and clone this repository.
2. Create a new branch in your fork based off the main branch.
3. Make your changes.
4. Commit your changes, and push them.
5. Submit a Pull Request.

## Contributing to the code
The issue tracker is for issue reporting or proposals/suggestions.  
To contribute to this repository, feel free to create a new fork of the repository and submit a pull request.

When contributing to the code, make sure to follow the code and test criteria in the [Definition of Done](https://docs.google.com/document/d/1jcstyrnsZCEZfqRqoAedoT1PsZBNXkdJ/edit?usp=sharing&ouid=105540361063195499886&rtpof=true&sd=true).

**Before committing and pushing your changes, please ensure that you do not have any linting errors!** <br>
You can check if you have any linting errors by using the sonarqube plugin (this plugin can be found in the Jetbrains marketplace), this gives you the ability to scan your files.

### Testing
Before making changes, contributors should check whether the code class they are working on already has a corresponding test file in the /test directory.
If a test file exists, it should be extended to cover any new or modified logic.   
If no test file exists yet, contributors are expected to create one.
All newly added lines of code must be covered by tests, and the full test suite should pass before submitting a pull request.

## Guidelines
There are a number of guidelines considered when reviewing Pull Requests to be merged. This is by no means an exhaustive list, but here are some things to consider before/while submitting your ideas.

Everything in the project should be generally useful for the majority of users. Don't let that stop you if you've got a good concept though, as your idea still might be a great addition.