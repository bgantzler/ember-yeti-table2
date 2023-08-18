import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';

import DEFAULT_THEME from 'ember-yeti-table2/themes/default-theme';

import { getOwner } from '@ember/application';
import { action, notifyPropertyChange } from '@ember/object';
import { once, scheduleOnce } from '@ember/runloop';
import { isEmpty, isPresent } from '@ember/utils';

import merge from 'deepmerge';

import filterData from 'ember-yeti-table2/utils/filtering-utils';
import {
  sortMultiple,
  compareValues,
  mergeSort,
} from 'ember-yeti-table2/utils/sorting-utils';

/**
 * bring ember-concurrency didCancel helper instead of
 * including the whole dependency
 */
const TASK_CANCELATION_NAME = 'TaskCancelation';
const didCancel = function (e) {
  return e && e.name === TASK_CANCELATION_NAME;
};

class PaginationData {
  @tracked
  pageSize;
  @tracked
  pageNumber;
  @tracked
  pageStart;
  @tracked
  pageEnd;
  @tracked
  isFirstPage;
  @tracked
  isLastPage;
  @tracked
  totalRows;
  @tracked
  totalPage;

  constructor(args) {
    Object.assign(this, args);
  }
}

/**
 The primary Yeti Table component. This component represents the root of the
 table, and manages high level state of all of its subcomponents.

 ```hbs
 <YetiTable @data={{this.data}} as |table|>

 <table.header as |header|>
 <header.column @prop="firstName">
 First name
 </header.column>
 <header.column @prop="lastName">
 Last name
 </header.column>
 <header.column @prop="points">
 Points
 </header.column>
 </table.header>

 <table.body/>

 </YetiTable>
 ```

 ```hbs
 <YetiTable @data={{this.data}} as |table|>

 <table.thead as |thead|>
 <thead.row as |row|>
 <row.column @prop="firstName">
 First name
 </row.column>
 <row.column @prop="lastName">
 Last name
 </row.column>
 <row.column @prop="points">
 Points
 </row.column>
 </thead.row>
 </table.thead>

 <table.body/>

 </YetiTable>
 ```

 @yield {object} table
 @yield {Component} table.header       the table header component (Single row in header)
 @yield {Component} table.thead        the table header component (Allows multiple rows in header)
 @yield {Component} table.body         the table body component
 @yield {Component} table.tfoot        the table footer component
 @yield {Component} table.pagination   the pagination controls component
 @yield {object} table.actions         an object that contains actions to interact with the table
 @yield {object} table.paginationData  object that represents the current pagination state
 @yield {boolean} table.isLoading      boolean that is `true` when data is being loaded
 @yield {array} table.columns          the columns on the table
 @yield {array} table.visibleColumns   the visible columns on the table
 @yield {array} table.rows             an array of all the rows yeti table knows of. In the sync case, it will contain the entire dataset. In the async case, it will be the same as `table.visibleRows`
 @yield {number} table.totalRows       the total number of rows on the table (regardless of pagination). Important argument in the async case to inform yeti table of the total number of rows in the dataset.
 @yield {array} table.visibleRows      the rendered rows on the table account for pagination, filtering, etc; when pagination is false, it will be the same length as totalRows
 @yield {object} table.theme           the theme being used
 */
// template imports
import { hash } from '@ember/helper';
import Table from 'ember-yeti-table2/components/yeti-table/table';
import Header from 'ember-yeti-table2/components/yeti-table/header';
import THead from 'ember-yeti-table2/components/yeti-table/thead';
import Body from 'ember-yeti-table2/components/yeti-table/body';
import TBody from 'ember-yeti-table2/components/yeti-table/tbody';
import TFoot from 'ember-yeti-table2/components/yeti-table/tfoot';
import Pagination from 'ember-yeti-table2/components/yeti-table/pagination';

export default class YetiTable extends Component {
  <template>
    {{this.fetchData1
      @loadData
      @data
      @pagination
      @pageNumber
      @pageSize
      this.FilterData
      this.sortData
    }}
    {{#let
      (hash
        table=(component Table theme=this.mergedTheme)
        header=(component
          Header
          columns=this.columns
          onColumnClick=this.onColumnSort
          sortable=this.sortable
          sortSequence=this.sortSequence
          parent=this
          theme=this.mergedTheme
        )
        thead=(component
          THead
          columns=this.columns
          onColumnClick=this.onColumnSort
          sortable=this.sortable
          sortSequence=this.sortSequence
          theme=this.mergedTheme
          parent=this
        )
        body=(component
          Body
          data=this.processedData
          columns=this.columns
          theme=this.mergedTheme
          parent=this
        )
        tbody=(component
          TBody
          data=this.processedData
          columns=this.columns
          theme=this.mergedTheme
          parent=this
        )
        tfoot=(component
          TFoot columns=this.columns theme=this.mergedTheme parent=this
        )
        pagination=(component
          Pagination
          disabled=this.isLoading
          theme=this.mergedTheme
          paginationData=this.paginationData
          paginationActions=(hash
            previousPage=this.previousPage
            nextPage=this.nextPage
            goToPage=this.goToPage
            changePageSize=this.changePageSize
          )
        )
        actions=this.publicApi
        paginationData=this.paginationData
        isLoading=this.isLoading
        columns=this.columns
        visibleColumns=this.visibleColumns
        rows=this.normalizedRows
        totalRows=this.normalizedTotalRows
        visibleRows=this.processedData
        theme=this.mergedTheme
      )
      as |api|
    }}
      {{#if this.renderTableElement}}
        <api.table ...attributes>
          {{yield api}}
        </api.table>
      {{else}}
        {{yield api}}
      {{/if}}

    {{/let}}
  </template>

  @tracked
  columns = [];

  @tracked
  resolvedData;

  /**
   * An object that contains classes for yeti table to apply when rendering its various table
   * html elements. The theme object your pass in will be deeply merged with yeti-table's default theme
   * and with a theme defined in your environment.js at `ENV['ember-yeti-table'].theme`.
   */
  get theme() {
    return this.args.theme ?? {};
  }

  // poor mans resource. Will update eventually
  get fetchData1() {
    this.fetchData();
    return '';
  }

  @action
  async fetchData() {
    if (this.loadData) {
      this.runLoadData();
    } else {
      // let _fetchData = async (data) => {
      let data = this.data;
      if (data !== this.oldData) {
        this.oldData = data;

        this.isLoading = true;
        try {
          let promise = typeof data === 'function' ? data() : data;
          const result = await promise;
          // check if data is still the same promise
          if (this.oldData === data) {
            //  && !this.isDestroyed) {
            this.resolvedData = result ?? [];
            this.isLoading = false;
            notifyPropertyChange(this, 'resolved');
          }
        } catch (e) {
          if (!didCancel(e)) {
            if (!this.isDestroyed) {
              this.isLoading = false;
            }
            // re-throw the non-cancellation error
            throw e;
          }
        }
      }
    }
    return '';
  }

  /**
   * The data for Yeti Table to render. It can be an array or a promise that resolves with an array.
   * The only case when `@data` is optional is if a `@loadData` was passed in.
   */
  oldData;
  get data() {
    return this.args.data;
  }

  /**
   * The function that will be called when Yeti Table needs data. This argument is used
   * when you don't have all the data available or loading all rows at once isn't possible,
   * e.g the dataset is too large.
   *
   * By passing in a function to `@loadData` you assume the responsibility to filter, sort and
   * paginate the data (if said features are enabled).
   *
   * This function must return an array or a promise that resolves with an array.
   *
   * This function will be called with an argument with the current state of the table.
   * Use this object to know what data to fetch, pass it to the server, etc.
   * Please check the "Async Data" guide to understand what that object contains and
   * an example of its usage.
   */
  get loadData() {
    return this.args.loadData;
  }

  publicApi = {
    previousPage: this.previousPage,
    nextPage: this.nextPage,
    goToPage: this.goToPage,
    changePageSize: this.changePageSize,
    reloadData: this.fetchData,
  };

  /**
   * This function will be called when Yeti Table initializes. It will be called with
   * an object argument containing the functions for the possible actions you can make
   * on a table. This object contains the following actions:
   *   - previousPage
   *   - nextPage
   *   - goToPage
   *   - changePageSize
   *   - reloadData
   */
  registerApi;

  /**
   * Use this argument to enable the pagination feature. Default is `false`.
   */
  get pagination() {
    return this.args.pagination ?? this.config.pagination ?? false;
  }

  /**
   * Controls the size of each page. Default is `15`.
   */
  get pageSize() {
    return this.args.pageSize ?? this.config.pageSize ?? 15;
  }

  /**
   * Controls the current page to show. Default is `1`.
   */
  @tracked
  _pageNumber = this.args.pageNumber ?? 1;
  get pageNumber() {
    return this.args.onPageNumberChanged
      ? this.args.pageNumber ?? 1
      : this._pageNumber;
  }
  set pageNumber(value) {
    this._pageNumber = value;
    this.args.onPageNumberChanged?.(value);
  }

  /**
   * Optional argument that informs yeti table of how many rows your data has.
   * Only needed when using a `@loadData` function and `@pagination={{true}}`.
   * When you use `@data`, Yeti Table uses the size of that array.
   * This information is used to calculate the pagination information that is yielded
   * and passed to the `@loadData` function.
   */
  get totalRows() {
    return this.args.totalRows;
  }

  /**
   * The global filter. If passed in, Yeti Table will search all the rows that contain this
   * string and show them. Defaults to `''`.
   */
  get filter() {
    return this.args.filter || '';
  }

  /**
   * An optional function to customize the filtering logic. This function should return true
   * or false to either include or exclude the row on the resulting set. If this function depends
   * on a value, pass that value as the `@filterUsing` argument.
   *
   * This function will be called with two arguments:
   * - `row` - the current data row to use for filtering
   * - `filterUsing` - the value you passed in as `@filterUsing`
   */
  get filterFunction() {
    return this.args.filterFunction;
  }

  /**
   * If you `@filterFunction` function depends on a different value (other that `@filter`)
   * to show, pass it in this argument. Yeti Table uses this argument to know when to recalculate
   * the fitlered rows.
   */
  get filterUsing() {
    return this.args.filterUsing;
  }

  @cached
  get filterData() {
    return {
      filter: this.filter,
      filterUsing: this.filterUsing,
      columnFilters: this.columns.map((c) => ({
        prop: c.prop,
        filter: c.filter,
        filterUsing: c.filterUsing,
      })),
    };
  }

  @cached
  get sortData() {
    return this.columns
      .filter((c) => !isEmpty(c.sort))
      .map((c) => ({
        prop: c.prop,
        direction: c.sort,
      }));
  }

  /**
   * Used to enable/disable sorting on all columns. You should use this to avoid passing
   * the @sortable argument to all columns.
   */
  get sortable() {
    return this.args.sortable ?? this.config.sortable ?? true;
  }

  /**
   * Use the `@sortFunction` if you want to completely customize how the row sorting is done.
   * It will be invoked with two rows, the current sortings that are applied and the `@compareFunction`.
   */
  get sortFunction() {
    return this.args.sortFunction ?? sortMultiple;
  }

  /**
   * Use `@compareFunction` if you just want to customize how two values relate to each other (not the entire row).
   * It will be invoked with two values and you just need to return `-1`, `0` or `1` depending on if first value is
   * greater than the second or not. The default compare function used is the `compare` function from `@ember/utils`.
   */
  get compareFunction() {
    return this.args.compareFunction ?? compareValues;
  }

  /**
   * Use `@sortSequence` to customize the sequence in which the sorting order will cycle when
   * clicking on the table headers. You can either pass in a comma-separated string or an array
   * of strings. Accepted values are `'asc'`, `'desc'` and `'unsorted'`. The default value is `['asc', 'desc']`.
   */
  get sortSequence() {
    return (
      this.args.sortSequence ?? this.config.sortSequence ?? ['asc', 'desc']
    );
  }

  /**
   * Use `@ignoreDataChanges` to prevent yeti table from observing changes to the underlying data and resorting or
   * refiltering. Useful when doing inline editing in a table.
   *
   * Defaults to false
   *
   * This is an initial render only value. Changing it after the table has been rendered will not be respected.
   *
   * @type {boolean}
   */
  get ignoreDataChanges() {
    return this.args.ignoreDataChanges ?? false;
  }

  /**
   * Use `@renderTableElement` to prevent yeti table from rendering the topmost <table> element.
   * Might be useful for styling purposes (e.g if you want to place your pagination controls outside
   * of your table element). If you set this to `false`, you should render the table element yourself
   * using the yielded `<t.table>` component.
   *
   * Defaults to true
   *
   * @type {boolean}
   */
  renderTableElement = this.args.renderTableElement ?? true;

  /**
   * The `@isColumnVisible` argument can be used to initialize the column visibility in a programmatic way.
   * For example, let's say you store the initial column visibility in local storage, then you can
   * use this function to initialize the `visible` column of the specific column. The given function should
   * return a boolean which will be assigned to the `visible` property of the column. An object representing
   * the column is passed in. You can use column.prop and column.name to know which column your computed
   * the visibility for.
   *
   * @type {Function}
   */
  get isColumnVisible() {
    return this.args.isColumnVisible;
  }

  // If the theme is replaced, this will invalidate, but not if any prop under theme is changed
  get mergedTheme() {
    let configTheme = this.config.theme ?? {};
    let localTheme = this.theme;
    return merge.all([DEFAULT_THEME, configTheme, localTheme]);
  }

  @tracked
  isLoading = false;

  @cached
  get visibleColumns() {
    return this.columns.filter((item) => item.visible === true);
  }

  @cached
  get config() {
    return (
      getOwner(this).resolveRegistration('config:environment')[
        'ember-yeti-table'
      ] || {}
    );
  }

  @cached
  get normalizedTotalRows() {
    if (!this.loadData) {
      // sync scenario using @data
      return this.sortedData?.length;
    } else {
      // async scenario. @loadData is present.
      if (this.totalRows === undefined) {
        // @totalRows was not passed in. Use the returned data set length.
        return this.resolvedData?.length;
      } else {
        // @totalRows was passed in.
        return this.totalRows;
      }
    }
  }

  @cached
  get normalizedRows() {
    if (!this.loadData) {
      // sync scenario using @data
      return this.sortedData;
    } else {
      // async scenario. @loadData is present.
      return this.resolvedData;
    }
  }

  @cached
  get paginationData() {
    let pageSize = this.pageSize;
    let pageNumber = this.pageNumber;
    let totalRows = this.normalizedTotalRows;
    let isLastPage, totalPages;

    if (totalRows) {
      totalPages = Math.ceil(totalRows / pageSize);
      pageNumber = Math.min(pageNumber, totalPages);
      isLastPage = pageNumber === totalPages;
    }

    let isFirstPage = pageNumber === 1;
    let pageStart = (pageNumber - 1) * pageSize;

    let pageEnd = pageStart + pageSize - 1;

    // make pageStart and pageEnd 1-indexed
    pageStart += 1;
    pageEnd += 1;

    if (totalRows) {
      pageEnd = Math.min(pageEnd, totalRows);
    }

    return new PaginationData({
      pageSize,
      pageNumber,
      pageStart,
      pageEnd,
      isFirstPage,
      isLastPage,
      totalRows,
      totalPages,
    });
  }

  @cached
  get pagedData() {
    let pagination = this.pagination;
    let data = this.sortedData;

    if (pagination) {
      let { pageStart, pageEnd } = this.paginationData;
      data = data.slice(pageStart - 1, pageEnd); // slice excludes last element so we don't need to subtract 1
    }

    return data;
  }

  @cached
  get processedData() {
    if (this.loadData) {
      // skip processing and return raw data if remote data is enabled via `loadData`
      return this.resolvedData;
    } else {
      return this.pagedData;
    }
  }

  constructor(owner, args) {
    super(owner, args);

    if (this.args.registerApi) {
      scheduleOnce('actions', null, this.args.registerApi, this.publicApi);
    }

    this.fetchData1;
  }

  @cached
  get filteredData() {
    // only columns that have filterable = true and a prop defined will be considered
    let columns = this.columns.filter((c) => c.filterable && isPresent(c.prop));

    return filterData(
      this.resolvedData,
      columns,
      this.filter,
      this.filterFunction,
      this.filterUsing,
    );
  }

  @cached
  get sortedData() {
    let data = this.filteredData;

    let sortableColumns = this.columns.filter((c) => !isEmpty(c.sort));
    let sortings = sortableColumns.map((c) => ({
      prop: c.prop,
      direction: c.sort,
    }));

    if (sortings.length > 0) {
      data = mergeSort(data, (itemA, itemB) => {
        return this.sortFunction(itemA, itemB, sortings, this.compareFunction);
      });
    }

    return data;
  }

  runLoadData() {
    if (
      isPresent(this.columns) &&
      this.loadData &&
      typeof this.loadData === 'function'
    ) {
      let param = {
        sortData: this.sortData,
        filterData: this.filterData,
      };

      if (this.pagination) {
        // cant use this.paginationData, if uses totalRows which could be changed as a result of this call
        let pageStart = (this.pageNumber - 1) * this.pageSize;
        param.paginationData = {
          pageSize: this.pageSize,
          pageNumber: this.pageNumber,
          pageStart: pageStart + 1, // make 1 indexed
          pageEnd: pageStart + this.pageSize - 1 + 1, // make 1 indexed
          isFirstPage: this.pageNumber === 1,
        };
      }

      let loadDataFunction = async (param) => {
        this.isLoading = true;
        try {
          let resolvedData = await this.loadData(param);
          if (!this.isDestroyed) {
            this.resolvedData = resolvedData;
            this.isLoading = false;
          }
        } catch (e) {
          if (!didCancel(e)) {
            if (!this.isDestroyed) {
              this.isLoading = false;
            }
            // re-throw the non-cancelation error
            throw e;
          }
        }
      };

      once(this, loadDataFunction, param);
    }
  }

  @action
  onColumnSort(column, e) {
    let direction;

    if (column.isSorted) {
      // if this column is already sorted, calculate the next
      // sorting on the sequence.
      direction = column.sort;
      let sortSequence = column.normalizedSortSequence;
      direction =
        sortSequence[
          (sortSequence.indexOf(direction) + 1) % sortSequence.length
        ];

      if (direction === 'unsorted') {
        direction = null;
      }
    } else {
      // use first direction from sort sequence
      direction = column.normalizedSortSequence[0];
      // create new sorting
    }

    column.sort = direction;

    if (!e.shiftKey) {
      // if not pressed shift, reset other column sortings
      let columns = this.columns.filter((c) => c !== column);
      columns.forEach((c) => (c.sort = null));
    }
  }

  @action
  previousPage() {
    if (this.pagination) {
      let { pageNumber } = this.paginationData;
      this.pageNumber = Math.max(pageNumber - 1, 1);
    }
  }

  @action
  nextPage() {
    if (this.pagination) {
      let { pageNumber, isLastPage } = this.paginationData;

      if (!isLastPage) {
        this.pageNumber = pageNumber + 1;
      }
    }
  }

  @action
  goToPage(pageNumber) {
    if (this.pagination) {
      let { totalPages } = this.paginationData;
      pageNumber = Math.max(pageNumber, 1);

      if (totalPages) {
        pageNumber = Math.min(pageNumber, totalPages);
      }

      this.pageNumber = pageNumber;
    }
  }

  @action
  changePageSize(pageSize) {
    if (this.pagination) {
      this.pageSize = parseInt(pageSize);
      this.pageSize = parseInt(pageSize);
    }
  }

  registerColumn(column) {
    let columns = this.columns;
    if (!columns.includes(column)) {
      this.columns.push(column);
      let notifyColumnsPropertyChange = () =>
        notifyPropertyChange(this, 'columns');
      once(notifyColumnsPropertyChange);
    }
  }

  unregisterColumn(column) {
    let columns = this.columns;
    if (columns.includes(column)) {
      this.columns = columns.filter((c) => c !== column);
    }
  }
}
