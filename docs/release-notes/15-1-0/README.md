---
title: OpenProject 15.1.0
sidebar_navigation:
    title: 15.1.0
release_version: 15.1.0
release_date: 2024-12-11
---

# OpenProject 15.1.0

Release date: 2024-12-11

We released OpenProject [OpenProject 15.1.0](https://community.openproject.org/versions/2122). The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes and technical updates. At the end, you will find a complete list of all changes and bug fixes.

## Important feature changes

### Custom fields of type hierarchy (Enterprise add-on)

Enterprise customers can now use a new type of custom field that allows for multi-level selections. This makes it easier for users to organize and navigate complex data in structured, multi-level formats within work packages. The new custom fields of the hierarchy type can be added to work packages and then structured into several lower-level values.

Each custom field of type hierarchy can be given a short name (e.g. B for Berlin).

![Example screenshot of custom fields of type hiearchy, displaying different cities as main offices](openproject-15-1-custom-field-hierarchy.jpg)

### Redesign of the Relations tab in work packages

### Redesign of the Meetings index page

### Manual page breaks in PDF work package exports

### Zen mode for project lists


## Important technical updates

### Possibility to lock seeded admin users, e.g. when using LDAP

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Multi-level selection fields to support custom hierarchical attributes \[[#36033](https://community.openproject.org/wp/36033)\]
- Bugfix: Unsorted &quot;User&quot; list in &quot;Time and costs&quot; \[[#43829](https://community.openproject.org/wp/43829)\]
- Bugfix: 500 when filtering by date field and specifying too big number \[[#55393](https://community.openproject.org/wp/55393)\]
- Bugfix: Sorting by custom field has strong impact on performance for the project list \[[#57305](https://community.openproject.org/wp/57305)\]
- Bugfix: Absent value for custom field is ordered not consistently at the beginning or end for different formats \[[#57554](https://community.openproject.org/wp/57554)\]
- Bugfix: Notification on a mention added to an edited comment is not triggered \[[#58007](https://community.openproject.org/wp/58007)\]
- Bugfix: Sidebar menu should be hidden when page width is reduced \[[#58454](https://community.openproject.org/wp/58454)\]
- Bugfix: Info box on new custom field of type hierarchy is permanent \[[#58466](https://community.openproject.org/wp/58466)\]
- Bugfix: Item add form disappears after added a new item to a custom field of type hierarchy \[[#58467](https://community.openproject.org/wp/58467)\]
- Bugfix: Using multi-select and required options do not work \[[#58635](https://community.openproject.org/wp/58635)\]
- Bugfix: HTML files served as plain text \[[#58646](https://community.openproject.org/wp/58646)\]
- Bugfix: Performance issues on work\_packages api endpoint \[[#58689](https://community.openproject.org/wp/58689)\]
- Bugfix: Breadcrumb of hierarchy items has left margin \[[#58700](https://community.openproject.org/wp/58700)\]
- Bugfix: Add local spacing to inline enterprise banner \[[#59284](https://community.openproject.org/wp/59284)\]
- Bugfix: Hierarchy custom fields causing 500 on custom actions \[[#59354](https://community.openproject.org/wp/59354)\]
- Bugfix: Signing in after two factor methods have been deleted lead to a 500 error \[[#59408](https://community.openproject.org/wp/59408)\]
- Bugfix: User without permission to &quot;Save views&quot; can save changes to work package views \[[#59479](https://community.openproject.org/wp/59479)\]
- Bugfix: Double provider showing on OpenID provider list \[[#59510](https://community.openproject.org/wp/59510)\]
- Bugfix: Hierarchy items not correctly displayed if custom field is shown in wp table \[[#59572](https://community.openproject.org/wp/59572)\]
- Bugfix: Buttons not visible on iOS in edit relations modal \[[#59772](https://community.openproject.org/wp/59772)\]
- Feature: Work package PDF export: Insert page breaks \[[#44047](https://community.openproject.org/wp/44047)\]
- Feature: Zen mode for project lists page \[[#52150](https://community.openproject.org/wp/52150)\]
- Feature: Create and edit custom field of type hierarchy \[[#57806](https://community.openproject.org/wp/57806)\]
- Feature: Enable ordering of hierarchy values of same level \[[#57820](https://community.openproject.org/wp/57820)\]
- Feature: Enable assignment of hierarchy values to work packages \[[#57824](https://community.openproject.org/wp/57824)\]
- Feature: Enable filtering on custom fields of type hierarchy \[[#57825](https://community.openproject.org/wp/57825)\]
- Feature: Primerised Meeting index pages \[[#57854](https://community.openproject.org/wp/57854)\]
- Feature: Re-design Relations tab according to  Figma mockups (Primerise) \[[#58345](https://community.openproject.org/wp/58345)\]
- Feature: Move primary action to subheader \[[#58636](https://community.openproject.org/wp/58636)\]
- Feature: Validate uniqueness of short names of hierarchy items \[[#58852](https://community.openproject.org/wp/58852)\]
- Feature: Add enterprise gateway to creation of custom fields of type hierarchy \[[#58865](https://community.openproject.org/wp/58865)\]
- Feature: Primer: Implement proper mobile behaviour for BoxTable \[[#59248](https://community.openproject.org/wp/59248)\]
- Feature: Allow locking of the seeded admin user \[[#59722](https://community.openproject.org/wp/59722)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A very special thank you goes to our sponsors of this release: Deutsche Bahn for sponsoring custom fields of type hierarchy, and City of Cologne for sponsoring zen mode for project lists.

Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes. Special thanks for reporting and finding bugs go to Bill Bai, Sam Yelman, Knight Chang, Gábor Alexovics, Gregor Buergisser, Andrey Dermeyko, Various Interactive, Clayton Belcher, Александр Татаринцев, and Keno Krewer.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings! This release we would like to highlight
- [José Helbert Pina](https://crowdin.com/profile/GZTranslations), for a great number of translations into Portuguese.
- [Alexander Aleschenko](https://crowdin.com/profile/top4ek), for a great number of translations into Russian.
- [Adam Siemienski](https://crowdin.com/profile/siemienas), for a great number of translations into Polish.

Would you like to help out with translations yourself? Then take a look at our [translation guide](../../contributions-guide/translate-openproject/) and find out exactly how you can contribute. It is very much appreciated!