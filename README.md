# experimental-annotation-swift


Librería que se usa para anidar anotaciones


# Swift Package Manager
Swift Package Manager es una herramienta para automatizar la distribución de código Swift y está integrado en el compilador Swift. Está en desarrollo temprano, pero experimental-annotation-swift admite su uso en plataformas compatibles.


Una vez que haya configurado su paquete Swift, agregar experimental-annotation-swift como dependencia es tan fácil como agregarlo al valor de dependencias de su Package.swift.
```
dependencies: [
    .package(url: "https://github.com/JavierSaldivarRubio/esperimental-annotation-swift", .upToNextMajor(from: "0.0.1"))
]
```

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Alamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'AnnotationSwift'
```



# Teoría
En java se conoce ya desde hace mucho tiempo las funciones denominadas anotaciones las cuales son muy comunes en sprint, o al usar la serialización con gson en android, en iOS no existía si no hace pocos años el uso de [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html)


Si bien es muy similar a las anotaciones de java, aun son muy simples y su principal limitante es que no se puede usar más de una anotación en una variable, 


```swift
@Upercase
@MaxLenght(10) //(X) Error Property type 'String?' does not match that of the 'wrappedValue' property of its wrapper type 'Email'
var name: String?
```
la intención de esta librería es poder crear grupos de annotaciones para cualquier fin.


#Documentación
[AnnotationSwift](./AnnotationSwift.doccarchive/index.html)
