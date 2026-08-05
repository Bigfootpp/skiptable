--!strict

export type Cursor<V> = {
	remove: () -> (),
    update: (value: V) -> ()
}


export type Generator<K, V> = () -> (K?, V?, Cursor<V>?)

export type IteratorPublic<K = any, V = any> = typeof(
	setmetatable({} :: {
		hasNext: (self: IteratorPublic<K, V>) -> boolean,
		next: (self: IteratorPublic<K, V>) -> (K?, V?, Cursor<V>?),
		iterate: (self: IteratorPublic<K, V>) -> Generator<K, V>
	}, {} :: {
		__iter: (self: IteratorPublic<K, V>) -> Generator<K, V>
	})
)

export type IteratorPrivate<K = any, V = any> = IteratorPublic<K, V> & {
	_current: Node<K, V>?,
	_maxKey: K,
	_lessFun: (K, K) -> boolean,
	_equalFun: (K, K) -> boolean,
	_skiptable: SkiptablePrivate<K, V>,
	_update: { Node<K, V> },
}

export type Node<K = any, V = any> = {
	key: K,
	value: V,
	nexts: { Node<K, V> },
	prev: { Node<K, V> },
}

export type CompFun<K> = (K, K) -> boolean

export type SkiptablePublic<K = any, V = any> = typeof(
	setmetatable({} :: {
		count: (self: SkiptablePublic<K, V>) -> number,
		clear: (self: SkiptablePublic<K, V>) -> (),
		first: (self: SkiptablePublic<K, V>) -> (K?, V?),
		last: (self: SkiptablePublic<K, V>) -> (K?, V?),
		set: (self: SkiptablePublic<K, V>, key: K, value: V) -> (),
		remove: (self: SkiptablePublic<K, V>, key: K) -> boolean,
		get: (self: SkiptablePublic<K, V>, key: K) -> V?,
		getRange: (self: SkiptablePublic<K, V>, minKey: K, maxKey: K, maxResults: number?) -> { V },
		iterRange: (self: SkiptablePublic<K, V>, minKey: K, maxKey: K) -> IteratorPublic<K, V>,
		iterAll: (self: SkiptablePublic<K, V>) -> IteratorPublic<K, V>,
	}, {} :: {
		__len: (self: SkiptablePublic<K, V>) -> number
	})
)

export type SkiptablePrivate<K = any, V = any> = SkiptablePublic<K, V> & {
	_lessFun: (K, K) -> boolean,
	_equalFun: (K, K) -> boolean,
	_head: Node<K, V>,
	_size: number,
	_getPredecessors: (self: SkiptablePrivate<K, V>, key: K) -> { Node<K, V> },
}

return {}
