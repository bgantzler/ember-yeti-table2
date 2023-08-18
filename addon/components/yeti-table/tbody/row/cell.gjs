import Component from '@glimmer/component';
import { registerDestructor } from '@ember/destroyable';

/**
 Renders a `<td>` element (if its corresponding column definition has `@visible={{true}}`).
 ```hbs
 <row.cell>
 {{person.firstName}}
 </row.cell>
 ```
 */
export default class TBodyCell extends Component {
  <template>
    {{#if this.column.visible}}
      <td
        class='{{@class}} {{this.column.columnClass}} {{@theme.tbodyCell}}'
        ...attributes
      >
        {{yield}}
      </td>
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
