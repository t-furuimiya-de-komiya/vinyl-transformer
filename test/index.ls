require! './test': {expect}
require! '..': vinyl-transformer


suite \vinylTransformer


function vtrans opts, f, recv
    t = vinyl-transformer opts, f, recv
    write: (x) ->
        new Promise (resolve, reject) ->
            t.once \error, reject
            t.once \transform-error, reject
            t.once \data, resolve
            t.write x
    transform-error: (x) ->
        new Promise (resolve, reject) ->
            t.once \error, reject
            t.once \transform-error, resolve
            t.once \data, reject
            t.write x


test 'transformer args' ->
    data = path: \hoge
    t = vtrans (file, ctx) !->
        expect @ .to.be.equal ctx
        expect file .to.be.equal data
        expect @file
        .to.be.equal data
        .to.be.equal file
        expect @filename .to.be.eql \hoge
    expect t.write data
    .to.become data


test 'using receiver' ->
    data = {}
    x = method: (file, ctx) !->
        expect @ .to.be.equal x
        expect file .to.be.equal data
        expect ctx.file
        .to.be.equal data
        .to.be.equal file
    t = vtrans x.method, x
    expect t.write data
    .to.become data


test 'encoding' ->
    t = vtrans {encoding: \utf8} ->
        expect @value .to.be.eql \abc
        \def
    expect t.write contents: Buffer.from \abc
    .to.become contents: Buffer.from \def, \utf8


test 'no encoding' ->
    t = vtrans ->
        expect @value .to.be.eql Buffer.from \abc
        Buffer.from \def
    expect t.write contents: Buffer.from \abc
    .to.become contents: Buffer.from \def


test 'return value is not buffer' ->
    t = vtrans ->
        expect @value .to.be.eql Buffer.from \abc
        42
    expect t.write contents: Buffer.from \abc
    .to.become contents: Buffer.from \abc


test 'transform error' ->
    err = new Error \trans
    t = vtrans ->
        throw err
    expect t.transform-error {}
    .to.become err


test 'return value is promise' ->
    t = vtrans -> Promise.resolve Buffer.from \abc
    expect t.write {}
    .to.become contents: Buffer.from \abc


test 'rejected promise returned' ->
    err = new Error \promise
    t = vtrans -> Promise.reject err
    expect t.transform-error {}
    .to.become err
