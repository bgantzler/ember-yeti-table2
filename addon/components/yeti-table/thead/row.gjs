import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
/**
 Renders a `<tr>` element and yields the column and cell component.
 ```hbs
 <table.thead as |head|>
 <head.row as |row|>
 <row.column @prop="firstName" as |column|>
 First name
 {{if column.isAscSorted "(sorted asc)"}}
 {{if column.isDescSorted "(sorted desc)"}}
 </head.column>
 </head.row>
 </table.thead>
 ```

 @yield {Component} column
 @yield {Component} cell
 */

import Column from 'ember-yeti-table2/components/yeti-table/thead/row/column';
import Cell from 'ember-yeti-table2/components/yeti-table/thead/row/cell';
import { hash } from '@ember/helper';

export default class THeadRow extends Component {
    <template>
        <tr class="{{@trClass}} {{@theme.theadRow}} {{@theme.row}}" ...attributes>
            {{yield (hash
                        column=(component Column
                            sortable=@sortable
                            sortSequence=@sortSequence
                            onClick=@onColumnClick
                            theme=@theme
                            parent=@parent
                        )
                        cell=(component Cell theme=@theme parent=this)
                    )}}
        </tr>
    </template>

    @tracked
    cells = [];

    registerCell(cell) {
        let column;

        if (cell.prop) {
            column = this.args.columns.find(c => c.prop === cell.prop);
        } else {
            let index = this.cells.length;
            column = this.args.columns[index];
        }

        cell.column = column;
        this.cells = [...this.cells, cell];

        return column;
    }

    unregisterCell(cell) {
        let cells = this.cells;
        let index = cells.indexOf(cell);

        this.cells = cells.toSpliced(index, 1);
    }
}
