import { render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test, skip } from 'qunit';

import { set, get, notifyPropertyChange } from '@ember/object';
import { run } from '@ember/runloop';
import { tracked } from '@glimmer/tracking';

// template imports
import YetiTable from 'ember-yeti-table2/components/yeti-table';
import { hash } from '@ember/helper';

class TestParams {
  @tracked
  filterText;
  @tracked
  filter;
  @tracked
  filterFirst;
  @tracked
  filterLast;
  @tracked
  min;
  @tracked
  max;
}

module('Integration | Component | yeti-table (filtering)', function (hooks) {
  setupRenderingTest(hooks);

  let data;

  hooks.beforeEach(function () {
    data = [
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
    ];
  });

  test('rendering with filter filters rows', async function (assert) {
    let testParams = new TestParams();
    testParams.filterText = "Baderous";
    await render(
    <template>
      <YetiTable @data={{data}} @filter={{testParams.filterText}} as |table|>

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

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
  });

  test('updating filter filters rows', async function (assert) {
    let testParams = new TestParams();

    await render(
        <template>
      <YetiTable @data={{data}} @filter={{testParams.filterText}} as |table|>

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
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('José');
    assert.dom('tbody tr:nth-child(3) td:nth-child(1)').hasText('Maria');
    assert.dom('tbody tr:nth-child(4) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(5) td:nth-child(1)').hasText('Tom');

    testParams.filterText = 'Baderous';
    await settled();

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
  });

  test('rendering with filter on column filters rows', async function (assert) {
    let testParams = new TestParams();
    testParams.filterText = 'Baderous';

    await render(
        <template>
      <YetiTable @data={{data}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @filter={{testParams.filterText}}>
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
          </template>);

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
  });

  test('updating filter on column filters rows', async function (assert) {
    let testParams = new TestParams();

    await render(
        <template>
      <YetiTable @data={{data}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName" @filter={{testParams.filterText}}>
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
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('José');
    assert.dom('tbody tr:nth-child(3) td:nth-child(1)').hasText('Maria');
    assert.dom('tbody tr:nth-child(4) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(5) td:nth-child(1)').hasText('Tom');

    testParams.filterText = 'Baderous';
    await settled();

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
  });

  test('rendering with filter on multiple column filters rows correctly', async function (assert) {
    let testParams = new TestParams();
    testParams.filterFirst = 'Tom';
    testParams.filterLast = '';

    await render(
        <template>
      <YetiTable @data={{data}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName" @filter={{testParams.filterFirst}}>
            First name
          </header.column>
          <header.column @prop="lastName" @filter={{testParams.filterLast}}>
            Last name
          </header.column>
          <header.column @prop="points">
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
          </template>);

    assert.dom('tbody tr').exists({ count: 2 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('Tom');

    testParams.filterLast = 'Dale';
    await settled();

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Dale');
  });

  test('changing a filtered property updates table', async function (assert) {
    await render(
        <template>
      <YetiTable @data={{data}} @filter="Tom" as |table|>

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

    assert.dom('tbody tr').exists({ count: 2 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('Tom');

      data[3].firstName = '123';
      notifyPropertyChange(data[3], 'firstName');
    await settled();

    assert.dom('tbody tr').exists({ count: 1 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
  });

  skip('changing a filtered property updates table is ignored correctly', async function (assert) {
    await render(
        <template>
      <YetiTable @data={{data}} @filter="Tom" @ignoreDataChanges={{true}} as |table|>

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

    assert.dom('tbody tr').exists({ count: 2 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('Tom');

      data[3].firstName = '123';
      notifyPropertyChange(data[3], 'firstName');
    await settled();

    assert.dom('tbody tr').exists({ count: 2 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('123');
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('Tom');
  });

  test('custom filter function', async function (assert) {
    let testParams = new TestParams();
    testParams.filterText = 'firstName:tom'

    testParams.filter = (row, filter) => {
      let [prop, text] = filter.split(':');

      if (prop && text) {
        let value = get(row, prop) || '';
        return value.toUpperCase().includes(text.toUpperCase());
      } else {
        return true;
      }
    };


    await render(
        <template>
      <YetiTable @data={{data}} @filterFunction={{testParams.filter}} @filterUsing={{testParams.filterText}} as |table|>

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

    assert.dom('tbody tr').exists({ count: 2 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('Tom');
    assert.dom('tbody tr:nth-child(2) td:nth-child(1)').hasText('Tom');

    testParams.filterText = 'lastName:baderous';
    await settled();

    assert.dom('tbody tr').exists({ count: 1 });
    assert.dom('tbody tr:nth-child(1) td:nth-child(2)').hasText('Baderous');
  });

  test('custom filter function and filterUsing', async function (assert) {
    let testParams = new TestParams();
    testParams.filter = (row, { min, max }) => {
      let points = row.points;
      return points >= min && points <= max;
    };

    testParams.min = 0;
    testParams.max = 100;

    await render(
        <template>
      <YetiTable @data={{data}} @filterUsing={{hash min=testParams.min max=testParams.max}} @filterFunction={{testParams.filter}} as |table|>

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

    testParams.min = 2;
    testParams.max = 4;
    await settled();

    assert.dom('tbody tr').exists({ count: 3 });
  });

  test('custom filter function and filterUsing on column', async function (assert) {
    let testParams = new TestParams();
    testParams.filter = (points, { min, max }) => {
      return points >= min && points <= max;
    };

    testParams.min = 0;
    testParams.max = 100;

    await render(
        <template>
      <YetiTable @data={{data}} as |table|>

        <table.header as |header|>
          <header.column @prop="firstName">
            First name
          </header.column>
          <header.column @prop="lastName">
            Last name
          </header.column>
          <header.column @prop="points" @filterUsing={{hash min=testParams.min max=testParams.max}} @filterFunction={{testParams.filter}}>
            Points
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
    </template>);

    assert.dom('tbody tr').exists({ count: 5 });

    testParams.min = 2;
    testParams.max = 4;
    await settled();

    assert.dom('tbody tr').exists({ count: 3 });
  });

  test('Filtering works when a column header does not have a property', async function (assert) {
    await render(
        <template>
      <YetiTable @data={{data}} @filter="Baderous" as |table|>

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
          <header.column>
            Test blank column
          </header.column>
        </table.header>

        <table.body/>

      </YetiTable>
          </template>);

    assert.dom('tbody tr').exists({ count: 1 });

    assert.dom('tbody tr:nth-child(1) td:nth-child(1)').hasText('José');
  });
});
