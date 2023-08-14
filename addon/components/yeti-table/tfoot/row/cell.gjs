import Component from '@glimmer/component';
import { registerDestructor } from '@ember/destroyable';


/**
 Renders a `<td>` element and yields for the developer to supply content.

 ```hbs
 <table.tfoot as |foot|>
 <foot.row as |row|>
 <row.cell>
 Footer content
 </row.cell>
 </foot.row>
 </table.tfoot>
 ```

 */

export default class TFootCell extends Component {
    <template>
        {{#if this.column.visible}}
            <td class="{{@class}} {{@theme.tfootCell}}" ...attributes>
                {{yield}}
            </td>
        {{/if}}
    </template>

    column;

    constructor() {
        super(...arguments);

        this.column = this.args.parent?.registerCell(this);
        registerDestructor(this, () => this.args.parent?.unregisterCell(this));
    }
}
