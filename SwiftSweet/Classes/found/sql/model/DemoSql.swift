//
// Created by entaoyang on 2019-02-23.
// Copyright (c) 2019 yet.net. All rights reserved.
//

import Foundation

func testSQL() {
//	testModel()
	let ls = Person._table.sqlite.tableInfo("Person")
	for c in ls {
		logd("Column: ", c.name, c.type)
	}
	let a = Person._table.sqlite.indexList("Person")
	for d in a {
		logd("Index: ", d.name)
	}
}

public func testModel() {
	Person._table.dropTable()
	Person._table.createTable()
	for i in 1...9 {
		let p = Person()
		p.name = "yang_\(i)"
		p.age = 30 + i
		p.insert()
	}
	Task.back {
		for _ in 0...100 {
			let p = Person()
			p.pid = 9
			p.update {
				p.name = "Entao "
				p.age = 999
			}
		}
		let ls = Person.find("pid" ?= 9, { $0.desc("pid") })
		for p in ls {
			p.dump()
		}
	}
	Task.back {
		for _ in 0...100 {
			let p = Person()
			p.pid = 9
			p.update {
				p.name = "Entao2 "
				p.age = 888
			}
		}
		let ls = Person.find("pid" ?= 9, { $0.desc("pid") })
		for p in ls {
			p.dump()
		}
	}

//	let ls = Person.find("pid" ?= 9, { $0.desc("pid") })
//	for p in ls {
//		p.dump()
//	}
}

@objcMembers
class Person: Model {

	dynamic var pid: Int = 0
	dynamic var name: String = ""
	dynamic var age: Int = 0
	dynamic var male: Bool = false
	dynamic var addr: String = ""

	override class func onTableDefine(_ table: Table) {
		table["pid"].PrimaryKey().AutoInc()
		table["name"].Index()
		table["age"].Index()
	}

	override class func onTableCreated(_ table: Table) {
		logd("Table Created, ", table.name)
	}

	func dump() {
		logd(pid, name, age, male)
	}

//	override var description: String {
//		return "\(pid), \(name), \(age), \(male)"
//	}

}

