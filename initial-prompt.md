Problematic: On OSX I often have to manually go clean System Data. I believe in previous versions of OSX you could do it through the Storage menu in the settings but no longer. In my case, it's often in the 200+ gb, which can be problematic on a 500gb SSD.

There are Apps out there that can help with this, but they are all premium apps, with no open source options out there. I want to initially brainstorm on how to solve this problem of mine, discuss tech stack for OSX (only), and provide a FOSS solution for people to use. I require there be a GUI, where you can see the files and folders that take up all the space, and the ability to manually clean up individual files, or multiples files, or individual folders, and multiple folders at once. Please research common folders that often get bloated, and provided sources to back your proposal up, this is to prevent hallucinations. Importnat system files MUST NEVER BE TOUCHED, this is NON-NEGOTIABLE. You must correctly identify those and blacklist those files/folders. Caches can be an exception but warnings must be provided. I've outline a very basic feature list, but I want you to also come up with more to incrementally build this up.

Tech stack:
- Backend: To be discussed and clarified

TDD is REQUIRED (non-negotiable):
- Follow Red–Green–Refactor.
- For every behavior in the specs, write tests FIRST (failing), then implement.
- The task list must explicitly sequence: tests → implementation → refactor.
- Always RUN tests after each implementation to ensure they pass.

Include a comprehensive README.md file in the root of the project that explains how to run the application and how to run the tests.

Extra
- Use the repo located on the local filesystem `/Users/cference/Code/claude-toolkit` for relevant skills and agents.

Features (minimal, more features to be added later, this is just to get started). Features will be described as Acceptance Criteria, use these for your TDD tests, additionally, think of at least two edge cases for the tests:
1. Basic Github Project Scaffolding with CICD on Github using Github Actions
   - Version Control should follow semantic versioning schema
   - `main` branch has the latest major release (this builds and ships the main package via CICD)
   - `development` branch has the latest dev changes (experimental builds)
   - Feel free to propose a different strategy (and update this spec as needed)
2. Basic Project that can be built through GitHub CICD, no features yet
3. Build the basic project that can compile
More features to come.

Constraints / non-goals:
- Provide Given/When/Then acceptance criteria with at least 2 edge cases per feature.
- Functional Programming highly desired over imperative style
- Best Coding practices encouraged
- Using type hints highly encouraged if language supports it
- Clean Code is a must
