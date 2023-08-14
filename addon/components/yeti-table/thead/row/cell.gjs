import Component from '@glimmer/component';
import { registerDestructor } from '@ember/destroyable';

/**
 An component yielded from the head.row component that is used to define
 a cell in a row of the head of the table. Would be used for filters or any other
 additional information in the table head for a column

 ```hbs
 <table.thead as |head|>
 <head.row as |row|>
 <row.cell>
 <input
 class="input" type="search" placeholder="Search last name"
 value={{this.lastNameFilter}}
 oninput={{action (mut this.lastNameFilter) value="target.value"}}>
 </row.cell>
 </head.row>
 </table.thead>
 ```

 @yield {object} cell

 */
export default class THeadCell extends Component {

    <template>
        {{#if this.column.visible}}
            <th class="{{@class}} {{@theme.theadCell}}" ...attributes>
                {{yield}}
            </th>
        {{/if}}
    </template>

    // Assigned when the cell is registered
    column;

    constructor() {
        super(...arguments);
        this.column = this.args.parent?.registerCell(this);
        registerDestructor(this, () => this.args.parent?.unregisterCell(this));
    }
}

