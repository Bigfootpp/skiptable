--!strict

export type Cursor<V> = {
	remove: () -> (),
    update: (value: V) -> ()
}

export type RangeIteratorPublic<K = any, V = any> = {
	hasNext: (self: RangeIteratorPublic<K, V>) -> boolean,
	next: (self: RangeIteratorPublic<K, V>) -> (K?, V?, Cursor<V>?),
	__iter: (self: RangeIteratorPublic<K, V>) -> () -> (K?, V?, Cursor<V>?),
}

export type Node<K = any, V = any> = {
	key: K,
	value: V,
	nexts: { Node<K, V> },
}

export type CompFun<K> = (K, K) -> boolean

export type SkiptablePublic<K = any, V = any> = {
	set: (self: SkiptablePublic<K, V>, key: K, value: V) -> (),
	remove: (self: SkiptablePublic<K, V>, key: K) -> boolean,
	get: (self: SkiptablePublic<K, V>, key: K) -> V?,
	getRange: (self: SkiptablePublic<K, V>, minKey: K, maxKey: K, maxResults: number?) -> { V },
	iterRange: (self: SkiptablePublic<K, V>, minKey: K, maxKey: K) -> RangeIteratorPublic<K, V>,
}

export type SkiptablePrivate<K = any, V = any> = SkiptablePublic<K, V> & {
	_lessFun: (K, K) -> boolean,
	_equalFun: (K, K) -> boolean,
	_head: Node<K, V>,
	_getPredecessors: (self: SkiptablePrivate<K, V>, key: K) -> { Node<K, V> },
}

export type RangeIteratorPrivate<K = any, V = any> = RangeIteratorPublic<K, V> & {
	_current: Node<K, V>?,
	_maxKey: K,
	_lessFun: (K, K) -> boolean,
	_equalFun: (K, K) -> boolean,
	_skiptable: SkiptablePrivate<K, V>,
	_update: { Node<K, V> },
}

return {}
