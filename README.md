# tl2swift

This project designated for parsing Telegram Type Language (.tl) specification for [TDLib](https://github.com/tdlib/td) and generating Swift code. <br>
`tl2swift` generates swift structures, enums and methods for working with TDLib json interface. See example in project [tdlib-swift](https://github.com/modestman/tdlib-swift)


### Usage 
```shell
$ swift run tl2swift td_api.tl ./output/
```

Set TDLib version & commit in header comment
```shell
$ swift run tl2swift td_api.tl ./output/ 1.7.5 73d8fb4
```
