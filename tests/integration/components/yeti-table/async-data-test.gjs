import {
  render,
  clearRender,
  settled,
  click,
  waitFor,
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import { A } from '@ember/array';
import { later } from '@ember/runloop';

import { hbs } from 'ember-cli-htmlbars';
import { restartableTask, timeout } from 'ember-concurrency';
import RSVP from 'rsvp';
import sinon from 'sinon';
import {tracked} from '@glimmer/tracking';

import {
  sortMultiple,
  compareValues,
  mergeSort,
} from 'ember-yeti-table2/utils/sorting-utils';

class TestParams {
  @tracked
  dataPromise;
  @tracked
  filterText;
  @tracked
  sortDir;
  @tracked
  pageNumber;
  @tracked
  totalRows;
}

import YetiTable from 'ember-yeti-table2/components/yeti-table';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';


module('Integration | Component | yeti-table (async)', function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.data = A([
      {
        firstName: 'Miguel',
        lastName: 'Andrade',
        points: 1,
      },
      {
        firstName: 'José',
        lastName: 'Baderous',
        points: 2,
      },
      {
        firstName: 'Maria',
        lastName: 'Silva',
        points: 3,
      },
      {
        firstName: 'Tom',
        lastName: 'Pale',
        points: 4,
      },
      {
        firstName: 'Tom',
        lastName: 'Dale',
        points: 5,
      },
    ]);
  });

  this.data2 = A([
    {
      firstName: 'A',
      lastName: 'B',
      points: 123,
    },
    {
      firstName: 'C',
      lastName: 'D',
      points: 456,
    },
    {
      firstName: 'E',
      lastName: 'F',
      points: 789,
    },
    {
      firstName: 'G',
      lastName: 'H',
      points: 321,
    },
    {
      firstName: 'I',
      lastName: 'J',
      points: 654,
    },
  ]);

  test('passing a promise as `data` works after resolving promise', async function (assert) {
    let testParams = new TestParams();
    testParams.dataPromise = [];

    await render(
    <template>
      <YetiTable @data={{testParams.dataPromise}} as |table|>

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
    </template>
    );

    testParams.dataPromise = new RSVP.Promise(
      (resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });

    assert.dom('tbody tr').doesNotExist();

    await settled();

    assert.dom('tbody tr').exists({ count: 5 });
  });

  test('yielded isLoading boolean is true while promise is not resolved', async function (assert) {
    let testParams = new TestParams();
    testParams.dataPromise = [];

    await render(
    <template>
      <YetiTable @data={{testParams.dataPromise}} as |table|>

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

        {{#if table.isLoading}}
          <div class="loading-message">Loading...</div>
        {{/if}}

      </YetiTable>
    </template>);

    testParams.dataPromise = new RSVP.Promise(
      (resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      }
    );

    await waitFor('.loading-message');

    assert.dom('.loading-message').hasText('Loading...');

    await settled();

    assert.dom('.loading-message').doesNotExist();
  });

  test('updating `data` after passing in a promise ignores first promise, respecting order', async function (assert) {
    let testParams = new TestParams();
    testParams.dataPromise = [];

    await render(
    <template>
      <YetiTable @data={{testParams.dataPromise}} as |table|>

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
    </template>);

    testParams.dataPromise = new RSVP.Promise(
      (resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      }
    );

    assert.dom('tbody tr').doesNotExist();

    testParams.dataPromise = new RSVP.Promise(
      (resolve) => {
        later(() => {
          resolve(this.data2);
        }, 10);
      }
    );

    await settled();

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('A');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('B');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('123');
  });

  test('yielded isLoading boolean is true while loadData promise is not resolved', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });
    });

    render(
    <template>
      <YetiTable @loadData={{loadData}} as |table|>

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

        {{#if table.isLoading}}
          <div class="loading-message">Loading...</div>
        {{/if}}

      </YetiTable>
    </template>);

    await waitFor('.loading-message');

    assert.dom('.loading-message').hasText('Loading...');

    await settled();

    assert.dom('.loading-message').doesNotExist();
  });

  test('loadData is called with correct parameters', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @filter="Miguel" as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @sort="desc" @filter="Andrade">
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 }, 'is not filtered');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(1)')
      .hasText('Tom', 'column 1 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(2)')
      .hasText('Dale', 'column 2 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(3)')
      .hasText('5', 'column 3 is not sorted');

    await clearRender();

    assert.ok(loadData.calledOnce, 'loadData was called once');
    assert.ok(
      loadData.firstCall.calledWithMatch({
        paginationData: undefined,
        sortData: [{ prop: 'lastName', direction: 'desc' }],
        filterData: {
          filter: 'Miguel',
          columnFilters: [
            { prop: 'firstName', filter: undefined, filterUsing: undefined },
            { prop: 'lastName', filter: 'Andrade', filterUsing: undefined },
            { prop: 'points', filter: undefined, filterUsing: undefined },
          ],
        },
      })
    );
  });

  test('loadData is called when updating filter', async function (assert) {
    assert.expect();
    let testParams = new TestParams();
    testParams.filterText = undefined;

    let loadData = sinon.spy(({ filterData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let data = this.data;

          if (filterData.filter) {
            data = data.filter((p) => p.lastName.includes(filterData.filter));
          }

          resolve(data);
        }, 150);
      });
    });

    await render(hbs`
      <YetiTable @loadData={{loadData}} @filter={{testParams.filterText}} as |table|>

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
    `);

    assert.dom('tbody tr').exists({ count: 5 }, 'is not filtered');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    testParams.filterText = 'Baderous';

    await settled();

    assert.dom('tbody tr').exists({ count: 1 }, 'is filtered');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(
      loadData.firstCall.calledWithMatch({ filterData: { filter: '' } })
    );
    assert.ok(
        loadData.secondCall.calledWithMatch({
        filterData: { filter: 'Baderous' },
      })
    );
  });

  test('loadData is called when updating sorting', async function (assert) {
    assert.expect();

    let testParams = new TestParams();

    let loadData = sinon.spy(({ sortData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let data = this.data;

          if (sortData.length > 0) {
            data = mergeSort(data, (itemA, itemB) => {
              return sortMultiple(itemA, itemB, sortData, compareValues);
            });
          }

          resolve(data);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @sort={{testParams.sortDir}}>
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Miguel');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Andrade');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('1');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    testParams.sortDir = 'desc';

    await settled();

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Maria');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Silva');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('3');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(loadData.firstCall.calledWithMatch({ sortData: [] }));
    assert.ok(
      loadData.secondCall.calledWithMatch({
        sortData: [{ prop: 'lastName', direction: 'desc' }],
      })
    );
  });

  test('loadData is called when clicking a sortable header', async function (assert) {
    assert.expect();

    let loadData = sinon.spy(({ sortData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let data = this.data;

          if (sortData.length > 0) {
            data = mergeSort(data, (itemA, itemB) => {
              return sortMultiple(itemA, itemB, sortData, compareValues);
            });
          }

          resolve(data);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} as |table|>

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
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Miguel');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Andrade');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('1');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    await click('thead tr th:nth-child(1)');

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Baderous');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('2');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(loadData.firstCall.calledWithMatch({ sortData: [] }));
    assert.ok(
      loadData.secondCall.calledWithMatch({
        sortData: [{ prop: 'firstName', direction: 'asc' }],
      })
    );
  });

  test('loadData is called when changing page', async function (assert) {
    assert.expect();

    let loadData = sinon.spy(({ paginationData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let pages = [this.data, this.data2];
          resolve(pages[paginationData.pageNumber - 1]);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @pagination={{true}} @totalRows={{10}} @pageSize={{5}} as |table|>

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

        <button id="next" type="button" {{on "click" table.actions.nextPage}}>
          Next
        </button>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Miguel');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Andrade');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('1');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    await click('button#next');

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('A');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('B');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('123');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(
      loadData.firstCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 1,
          pageStart: 1,
          pageEnd: 5,
          isFirstPage: true,
          isLastPage: false,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );

    assert.ok(
      loadData.secondCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 2,
          pageStart: 6,
          pageEnd: 10,
          isFirstPage: false,
          isLastPage: true,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );
  });

  test('loadData is called when changing page through @pageNumber arg', async function (assert) {
    assert.expect();

    let loadData = sinon.spy(({ paginationData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let pages = [this.data, this.data2];
          resolve(pages[paginationData.pageNumber - 1]);
        }, 150);
      });
    });

    let testParams = new TestParams();
    testParams.pageNumber = 1;

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @pagination={{true}} @totalRows={{10}} @pageSize={{5}} @pageNumber={{testParams.pageNumber}} as |table|>

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

        <button id="next" type="button" {{on "click" table.actions.nextPage}}>
          Next
        </button>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Miguel');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Andrade');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('1');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    testParams.pageNumber = 2;

    await settled();

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('A');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('B');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('123');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(
      loadData.firstCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 1,
          pageStart: 1,
          pageEnd: 5,
          isFirstPage: true,
          isLastPage: false,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );

    assert.ok(
      loadData.secondCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 2,
          pageStart: 6,
          pageEnd: 10,
          isFirstPage: false,
          isLastPage: true,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );
  });

  test('loadData is called when changing page with @onPageNumberChange (see #301)', async function (assert) {
    assert.expect();

    let loadData = sinon.spy(({ paginationData }) => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          let pages = [this.data, this.data2];
          resolve(pages[paginationData.pageNumber - 1]);
        }, 150);
      });
    });

    let testParams = new TestParams();
    testParams.pageNumber = 1;

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @pagination={{true}} @totalRows={{10}} @pageSize={{5}} @pageNumber={{testParams.pageNumber}} as |table|>

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

        <button id="next" type="button" {{on "click" table.actions.nextPage}}>
          Next
        </button>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Miguel');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Andrade');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('1');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    await click('button#next');

    assert.dom('tbody tr').exists({ count: 5 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('A');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('B');
    assert.dom('tbody tr:nth-child(1) td:nth-child(3)').hasText('123');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
    assert.ok(
      loadData.firstCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 1,
          pageStart: 1,
          pageEnd: 5,
          isFirstPage: true,
          isLastPage: false,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );

    assert.ok(
      loadData.secondCall.calledWithMatch({
        paginationData: {
          pageSize: 5,
          pageNumber: 2,
          pageStart: 6,
          pageEnd: 10,
          isFirstPage: false,
          isLastPage: true,
          totalRows: 10,
          totalPages: 2,
        },
      })
    );
  });

  test('loadData is called once if updated totalRows on the loadData function', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          this.set('totalRows', this.data.length);
          resolve(this.data);
        }, 150);
      });
    });

    let testParams = new TestParams();

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @pagination={{true}} @pageSize={{10}} @totalRows={{testParams.totalRows}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @sort="desc">
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 }, 'is not filtered');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(1)')
      .hasText('Tom', 'column 1 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(2)')
      .hasText('Dale', 'column 2 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(3)')
      .hasText('5', 'column 3 is not sorted');

    await clearRender();

    assert.ok(loadData.calledOnce, 'loadData was called once');
  });

  test('loadData is called once if we change @filter from undefined to ""', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });
    });

    let testParams = new TestParams();

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @filter={{testParams.filterText}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @sort="desc">
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 }, 'is not filtered');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(1)')
      .hasText('Tom', 'column 1 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(2)')
      .hasText('Dale', 'column 2 is not sorted');
    assert
      .dom('tbody tr:nth-child(5) td:nth-child(3)')
      .hasText('5', 'column 3 is not sorted');

    testParams.filterText = '';

    await clearRender();

    assert.ok(this.loadData.calledOnce, 'loadData was called once');
  });

  test('loadData can be an ember-concurrency restartable task and be cancelled', async function (assert) {
    assert.expect(4);
    let data = this.data;
    let spy = sinon.spy();
    let hardWorkCounter = 0;

    class Obj {
      @restartableTask
      *loadData() {
        spy(...arguments);
        yield timeout(100);
        hardWorkCounter++;
        return data;
      }
    }

    let obj = new Obj();

    let testParams = new TestParams();
    testParams.filterText = 'Migu';

    render(<template>
      <YetiTable @loadData={{perform obj.loadData}} @filter={{testParams.filterText}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @sort="desc">
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    setTimeout(() => {
      testParams.filterText = 'Tom';
    }, 50);

    await settled();

    assert.ok(
      spy.calledTwice,
      'load data was called twice (but one was cancelled)'
    );
    assert.ok(
      spy.firstCall.calledWithMatch({ filterData: { filter: 'Migu' } })
    );
    assert.ok(
      spy.secondCall.calledWithMatch({ filterData: { filter: 'Tom' } })
    );
    assert.equal(hardWorkCounter, 1, 'only did the "hard work" once');
  });

  test('reloadData from @registerApi reruns the @loadData function', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} @registerApi={{fn (mut this.tableApi)}} as |table|>

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
    </template>);

    assert.dom('tbody tr').exists({ count: 5 }, 'has only five rows');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    this.data.addObject({
      firstName: 'New',
      lastName: 'User',
      points: 12,
    });

    this.tableApi.reloadData();
    await settled();

    assert
      .dom('tbody tr')
      .exists({ count: 6 }, 'has an additional row from the reloadData call');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
  });

  test('reloadData from yielded action reruns the @loadData function', async function (assert) {
    let loadData = sinon.spy(() => {
      return new RSVP.Promise((resolve) => {
        later(() => {
          resolve(this.data);
        }, 150);
      });
    });

    await render(
    <template>
      <YetiTable @loadData={{loadData}} as |table|>

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

        <button id="reload" type="button" disabled={{table.isLoading}} {{on "click" table.actions.reloadData}}>
          Reload
        </button>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 }, 'has only five rows');

    assert.ok(loadData.calledOnce, 'loadData was called once');

    this.data.addObject({
      firstName: 'New',
      lastName: 'User',
      points: 12,
    });

    await click('button#reload');

    assert
      .dom('tbody tr')
      .exists({ count: 6 }, 'has an additional row from the reloadData call');

    await clearRender();

    assert.ok(loadData.calledTwice, 'loadData was called twice');
  });
});
