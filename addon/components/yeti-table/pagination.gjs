import Component from '@glimmer/component';
import { action } from '@ember/object';

/**
 Simple pagination controls component that is included to help you get started quickly.
 Yeti Table yields a lot of pagination data, so you shouldn't have a problem
 creating your own pagination controls.

 At any rate, this component tries to be as flexible as possible. Some arguments
 are provided to customize how this component behaves.

 If you want to render these controls on the table footer, you probably want
 a footer row that always spans all rows. To do that you can use a `colspan` equal
 to the yielded `visibleColumns.length` number. Example:

 ```hbs
 <YetiTable @data={{this.data}} @pagination={{true}} as |table|>
 ...
 <table.tfoot as |foot|>
 <foot.row as |row|>
 <row.cell colspan={{table.visibleColumns.length}}>
 <table.pagination/>
 </row.cell>
 </foot.row>
 </table.tfoot>
 </YetiTable>
 ```
 */
import { on } from '@ember/modifier';

export default class Pagination extends Component {
  <template>
    {{! template-lint-disable require-input-label }}
    <div class={{@theme.pagination.controls}} ...attributes>
      {{#if this.showInfo}}
        <div class={{@theme.pagination.info}}>
          Showing
          {{@paginationData.pageStart}}
          to
          {{@paginationData.pageEnd}}
          of
          {{@paginationData.totalRows}}
          entries
        </div>
      {{/if}}

      {{#if this.showPageSizeSelector}}
        <div class={{@theme.pagination.pageSize}}>
          Rows per page:
          <select disabled={{@disabled}} {{on 'change' this.changePageSize}}>
            {{#each this.pageSizes as |pageSize|}}
              <option
                value={{pageSize}}
                selected={{this.isEqualHelper
                  @paginationData.pageSize
                  pageSize
                }}
              >
                {{pageSize}}
              </option>
            {{/each}}
          </select>
        </div>
      {{/if}}

      {{#if this.showButtons}}
        <button
          type='button'
          class={{@theme.pagination.previous}}
          disabled={{this.shouldDisablePrevious}}
          {{on 'click' @paginationActions.previousPage}}
        >
          Previous
        </button>

        <button
          type='button'
          class={{@theme.pagination.next}}
          disabled={{this.shouldDisableNext}}
          {{on 'click' @paginationActions.nextPage}}
        >
          Next
        </button>
      {{/if}}
    </div>
  </template>

  theme;

  isEqualHelper(a, b) {
    return a === b;
  }

  get paginationData() {
    return this.args.paginationData;
  }

  get paginationActions() {
    return this.args.paginationActions;
  }

  get disabled() {
    return this.args.disabled;
  }

  shouldDisablePrevious() {
    return this.paginationData.isFirstPage || this.disabled;
  }

  get shouldDisableNext() {
    return this.paginationData.isLastPage || this.disabled;
  }

  /**
   * Array of page sizes to populate the page size `<select>`.
   * Particularly useful with an array helper, e.g `@pageSizes={{array 10 12 23 50 100}}`
   * Defaults to `[10, 15, 20, 25]`.
   */
  pageSizes = [10, 15, 20, 25];

  /**
   * Used to show/hide some textual information about the current page. Defaults to `true`.
   */
  get showInfo() {
    return this.args.showInfo ?? true;
  }

  /**
   * Used to show/hide the previous and next page buttons. Defaults to `true`.
   */
  showButtons = true;

  /**
   * Used to show/hide the page size selector. Defaults to `true`.
   */
  get showPageSizeSelector() {
    return this.args.showPageSizeSelector ?? true;
  }

  @action
  changePageSize(ev) {
    this.paginationActions.changePageSize(ev.target.value);
  }
}
