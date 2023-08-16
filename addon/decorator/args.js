import { DEBUG } from '@glimmer/env';
export const arg = (...args) => {
    const [target, key, descriptor] = args;
    let options = {};
    // Error on `@arg()`
    if (DEBUG && target === undefined) throwTrackedWithEmptyArgumentsError();

    if (descriptor) {
        return descriptorForField(target, key, descriptor);
    }
    // In TypeScript's implementation, decorators on simple class fields do not
    // receive a descriptor, so we define the property on the target directly.
    Object.defineProperty(target, key, descriptorForField(target, key), options);
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
    let savedValue;
    let onChangedProperty = `on{$key}Changed`;
    let descriptor =
    {
        enumerable: true,
        configurable: true,

        get(self) {
            debugger;
            return self.args[onChangedProperty] ? self.args[key] : savedValue ?? options.default;
        },
    };

    if (options.updatable) {
        descriptor.set = function(self, newValue) {
            debugger;
            savedValue = newValue;
            self.args[onChangedProperty]?.(newValue);
        }
    }
}
