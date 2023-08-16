import { DEBUG } from '@glimmer/env';
import {cell} from 'ember-resources';

/**
 Arg decorator

 useage:

 @arg
 data;

 This creates a property on the class that just returns the this.args property
 that was passed in. The property is read only

 @arg({default:1})
 data;

 This creates a property on the class that just returns the this.args property
 that was passed in. if the property passed in is not defined, the default
 value is used to initialize the value. Any changes to this.args is
 properly reflected. The property is read only

 @arg({updatable: true})
 data;

 This creates a property on the class that is initialized to the value that
 is passed in. It then becomes updatable within the class. Any changes to the
 passed in value are not reflected.

 An onChange arg named for the property, in this case onDataChange, is monitored.
 If changes passed wish to be accepted, the consumer would pass in a function
 that would accept the new value and change the value that is then passed in.
 **/

export const arg = function(options = {}) {
    debugger;
    return (...args) => {
        debugger;
        const [target, key, descriptor] = args;
        // Error on `@arg()`
        if (DEBUG && target === undefined) throwTrackedWithEmptyArgumentsError();

        if (descriptor) {
            return descriptorForField(target, key, descriptor, options);
        }
        // In TypeScript's implementation, decorators on simple class fields do not
        // receive a descriptor, so we define the property on the target directly.
        Object.defineProperty(target, key, descriptorForField(target, key, undefined, options));
    };
};

function throwTrackedWithEmptyArgumentsError() {
    throw new Error(
        'You attempted to use @arg(), which is no longer necessary nor supported. Remove the parentheses and you will be good to go!'
    );
}

function descriptorForField(
    _target,
    key,
    desc,
    options
) {
    let savedValue = new cell(options.default);
    let capProperty = key.charAt(0).toUpperCase() + key.slice(1)
    let onChangedProperty = `on${capProperty}Changed`;
    let descriptor =
    {
        enumerable: true,
        configurable: true,

        get() {
            return this.args[onChangedProperty] ? this.args[key] : savedValue.current;
        },
    };

    if (options.updatable) {
        descriptor.set = function(newValue) {
            debugger;
            savedValue.current = newValue;
            this.args[onChangedProperty]?.(newValue);
        }
    }

    return descriptor;
}