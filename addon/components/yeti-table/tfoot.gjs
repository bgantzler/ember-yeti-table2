/**
 Renders a `<tfoot>` element and yields the row component.
 ```hbs
 <table.tfoot as |foot|>
 <foot.row as |row|>
 <row.cell>
 Footer content
 </row.cell>
 </foot.row>
 </table.tfoot>
 ```

 @yield {object} footer
 @yield {Component} footer.row
 */
import { hash } from '@ember/helper';
import TFootRow from 'ember-yeti-table2/components/yeti-table/tfoot/row';

<template>
  <tfoot class={{@theme.tfoot}} ...attributes>
    {{yield
      (hash
        row=(component TFootRow columns=@columns theme=@theme parent=@parent)
      )
    }}
  </tfoot>
</template>
