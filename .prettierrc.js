'use strict';

module.exports = {
  plugins: ['prettier-plugin-ember-template-tag'],
  overrides: [
    {
      files: '*.{gjs,gts,js,ts}',
      options: {
        singleQuote: true,
      },
    },
  ],
};
