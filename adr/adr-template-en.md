---
# These are optional metadata elements. Feel free to remove any of them.
status: "{proposed | rejected | accepted | deprecated | … | superseded by ADR-NNNN}"
date: {YYYY-MM-DD when the decision was last updated}
decision-makers: {list everyone involved in the decision}
consulted: {list everyone whose opinions are sought (typically subject-matter experts); and with whom there is a two-way communication}
informed: {list everyone who is kept up-to-date on progress; and with whom there is a one-way communication}
---

# {short title, representative of solved problem and found solution}

## Context and Problem Statement

💬 Describes the forces at play, including technical, political, social, and project-specific factors, and frames the decision problem that needs to be addressed.

➥ Describe the context and problem statement, e.g., in free form using two to three sentences or in the form of an illustrative story. You may want to articulate the problem in form of a question and add links to collaboration boards or issue management systems.

💡 Tips:
Keep the context focused on what is relevant to the decision; move background material to external references.
Phrase the problem as a clear question to make the decision outcome verifiable against it.
Link to related artifacts (SRS requirement IDs, SDD design elements, prior ADRs) where applicable.

<!-- This is an optional element. Feel free to remove. -->

## Decision Drivers

💬 Lists the criteria, constraints, and priorities that influence the choice among the considered options.

➥ Enumerate the forces and concerns that shape the decision, e.g., performance targets, security constraints, cost limits, team expertise, deadlines, regulatory obligations.

* {decision driver 1, e.g., a force, facing concern, …}
* {decision driver 2, e.g., a force, facing concern, …}
* … <!-- numbers of drivers can vary -->

💡 Tips:
Order drivers by importance so readers can see which criteria dominate the decision.
Where possible, reference measurable criteria from the SRS (e.g., REQ-PERF-001 latency target).

## Considered Options

➥ List the realistic alternatives that were evaluated. Include the chosen option here as well, and do not include options that were dismissed before serious consideration.

* {title of option 1}
* {title of option 2}
* {title of option 3}
* … <!-- numbers of options can vary -->

💡 Tips:
Keep option titles short and consistent in phrasing so they can be referenced in "Pros and Cons of the Options".
If an option is described in a separate document or POC report, link to it instead of duplicating the description.

## Decision Outcome

💬 States the chosen option and provides the justification that explains why it was selected over the alternatives.

➥ Chosen option: "{title of option 1}", because {justification. e.g., only option, which meets a knock-out (k.o.) criterion | which resolves the force {force} | … | comes out best (see below)}.

<!-- This is an optional element. Feel free to remove. -->

### Consequences

💬 Records the positive, negative, and neutral effects of the decision, including follow-up obligations.

* Good, because {positive consequence, e.g., improvement of one or more desired qualities, …}
* Bad, because {negative consequence, e.g., compromising one or more desired qualities, …}
* … <!-- numbers of consequences can vary -->

💡 Tips:
Be honest about trade-offs; hidden downsides discovered later undermine trust in the decision process.
Note any new requirements, follow-up decisions, or mitigations that this decision creates.

<!-- This is an optional element. Feel free to remove. -->

### Confirmation

💬 Describes how compliance with this decision will be verified during implementation and operation.

➥ Describe how the implementation of/compliance with the ADR can/will be confirmed. Is the chosen design and its implementation in line with the decision? E.g., a design/code review or a test with a library such as ArchUnit can help validate this.

💡 Tips:
Although this element is classified as optional, it is included in many ADRs.
Automated checks (linters, architecture tests, CI gates) are preferred over manual confirmation.

<!-- This is an optional element. Feel free to remove. -->

## Pros and Cons of the Options

💬 Provides a structured comparison of each considered option, making the justification of the outcome transparent.

<!-- use "neutral" if the given argument weights neither for good nor bad -->

### {title of option 1}

{example | description | pointer to more information | …}

* Good, because {argument a}
* Good, because {argument b}
<!-- use "neutral" if the given argument weights neither for good nor bad -->
* Neutral, because {argument c}
* Bad, because {argument d}
* … <!-- numbers of pros and cons can vary -->

### {title of other option}

{example | description | pointer to more information | …}

* Good, because {argument a}
* Good, because {argument b}
* Neutral, because {argument c}
* Bad, because {argument d}
* …

💡 Tips:
Use the same argument structure for every option so the comparison is symmetric and easy to audit.
Arguments should trace back to the Decision Drivers listed above.

<!-- This is an optional element. Feel free to remove. -->

## More Information

💬 Provides supplementary evidence, links, and follow-up notes that support the decision and its future revisiting.

➥ You might want to provide additional evidence and confidence for the decision outcome here and/or document the team agreement on the decision and/or define when/how this decision should be realized and if/when it should be re-visited. Links to other decisions and resources might appear here as well.

💡 Tips:
Record the review or meeting where the decision was agreed, if applicable.
State the conditions under which this decision should be revisited (e.g., new evidence, changed constraints).
Link to the SRS requirements and SDD design elements affected by this decision.
