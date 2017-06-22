const stream = require('stream')
const assert = require('assert')


module.exports = function vinylTransformer(opts, f, recv)
{
    if (typeof f !== 'function') {
        recv = f
        f = opts
        opts = null
    }
    opts = Object.assign({}, opts)

    assert(typeof f === 'function')
    assert(opts)

    return new stream.Transform({objectMode: true,
        transform(file, _, done)
        {
            transformImpl(file, this)
            .then(_ => done(null))
            .catch(done)
        }
    })

    async function transformImpl(file, self)
    {
        if (!file)
            return
        try {
            const {encoding} = opts

            let value = file.contents
            if (Buffer.isBuffer(value) && Buffer.isEncoding(encoding))
                value = value.toString(encoding)

            filename = file.path

            const ctx = {file, value, filename}

            let ret = await f.call(recv || ctx, file, ctx)

            if (typeof ret === 'string' && Buffer.isEncoding(encoding))
                ret = Buffer.from(ret, encoding)
            if (Buffer.isBuffer(ret))
                file.contents = ret

            self.push(file)

        } catch (err) {
            self.emit('transform-error', err)
        }
    }
}
