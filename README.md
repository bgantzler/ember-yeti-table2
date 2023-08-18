# ember-yeti-table2

[Short description of the addon.]

## Compatibility

- Ember.js v4.4 or above
- Ember CLI v4.4 or above
- Node.js v16 or above

## Installation

```
ember install ember-yeti-table2
```

## Usage

[Longer description of how to use the addon in apps.]

## Contributing

See the [Contributing](CONTRIBUTING.md) guide for details.

## License

This project is licensed under the [MIT License](LICENSE.md).

# Breaking changes

Component is not exported, it will be available as an import only for templates. However, if you want
to use it in an hbs, you will need to create the app/component file yourself. If migrating from ember-yeti-table
and wanting to use both in hbs you should create a file with a different name. This will allow you to use
both in HBS. The recommended approach would be to use template imports and import this addons version of the 
component. 
```js
export { default } from 'ember-yeti-table2/components/yeti-table';
```
## Glimmer components
All components are now glimmer. Any dependency on two-way bound arguments are no longer valid.

Because glimmer is not two-way bound, the sort property and pageNumber property will be the initial only. 
If you wish to change them, you have to supply an onSortChanged or an onPageNumberChanged function and change 
the value passed in. 

## Data must be tracked

The computed was built dynamically to look at data and its properties and add the properties referenced to the
computed dependency list. With glimmer, the data must be marked accordingly with tracked or a notifyPropertyChange
is issued when the data is altered.

## loadData method and isLastPage, totalRows, TotalPages

The paginationData variable passed to loadData will no longer contain isLastPage, TotalRows and TotalPages.
You should have the data to calculate these yourself. Since calling loadData could change totalRows, 
these perperties can no longer be access to pass as params as it woulod cause an infinate loop.

pageNumber will not be minned if greater than totalPages and pageEnd will not be minned if greater 
than totalRows for the same reason. 

# Due to glimmer components not being two-way bound and need for DDAU

Sort is initial only. To allow changes, you have to supply an onSortChanged function and change the value passed in
PageNumber is initial only. To allow changes, you have to supply an onPageNumberChanged function and change the value passed in

# ignoreDataChanges
Before this was able to be turned off by dynamically creating the computed statements. Because tracking is now
being used, this can no longer be done. The only way I can think of implementing this feature
is by you passing in data that is not marked as tracked. Therefor implementing this feature may be work on your part

