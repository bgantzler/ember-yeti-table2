# ember-yeti-table2

[Short description of the addon.]


## Compatibility

* Ember.js v4.4 or above
* Ember CLI v4.4 or above
* Node.js v16 or above


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



## Breaking change.

# Du to glimmer not being two-way bound and need for DDAU
Sort is initial only. To allow changes, you have to supply an onSortChanged function and change the value passed in
PageNumber is initial only. To allow changes, you have to supply an onPageNumberChanged function and change the value passed in 

# Due to reactive natute, causes an infinite loop
The paginationData variable passed to loadData will no longer contain TotalRows and TotalPages. 
    You should have the data to calculate these yourself
    pageNumber will not be minned if greater than number of pages
    pageEnd will not be minned if greater than totalRows
