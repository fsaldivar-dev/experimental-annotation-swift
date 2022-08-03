# experimental-annotation-swift

<img width="480" alt="AnnotationSwift" src="https://user-images.githubusercontent.com/16517868/182271709-188b8cfb-1ac7-4e8e-b062-b3ee121bd92f.png">


![GitHub issues:	GitHub issues badge](https://img.shields.io/github/issues/fsaldivar-dev/experimental-annotation-swift)
![GitHub forks:	GitHub forks badge](https://img.shields.io/github/forks/fsaldivar-dev/experimental-annotation-swift)
[![GitHub stars](https://img.shields.io/github/stars/fsaldivar-dev/experimental-annotation-swift?style=for-the-badge)](https://github.com/fsaldivar-dev/experimental-annotation-swift/stargazers)

![GitHub license:	GitHub license badge](https://img.shields.io/github/license/fsaldivar-dev/experimental-annotation-swift)
![Cocoapods](https://img.shields.io/cocoapods/v/AnnotationSwift)
[![Build](https://github.com/fsaldivar-dev/experimental-annotation-swift/actions/workflows/Build.yml/badge.svg)](https://github.com/fsaldivar-dev/experimental-annotation-swift/actions/workflows/Build.yml)
[![Test](https://github.com/fsaldivar-dev/experimental-annotation-swift/actions/workflows/UnitTest.yml/badge.svg)](https://github.com/fsaldivar-dev/experimental-annotation-swift/actions/workflows/UnitTest.yml)

# Coverage
Total Coverage: <b>92.39%</b>

<details><summary>Coverage Report</summary><table><tbody><tr><th>File</th><th>Branches</th><th>Funcs</th><th>Lines</th><th>Uncovered Lines</th></tr><tr><td colspan='5'><b>Sources</b></td></tr><tr><td>&nbsp; &nbsp;<a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift'>experimental_annotation.swift</a></td><td>100%</td><td><b>75%</b></td><td><b>78.57%</b></td><td><a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L15'>15</a>, <a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L16'>16</a>, <a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L17'>17</a>, <a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L19'>19</a>, <a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L20'>20</a>, <a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/experimental_annotation.swift#L21'>21</a></td></tr><tr><td colspan='5'><b>Sources/annotations</b></td></tr><tr><td>&nbsp; &nbsp;<a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/annotations/EmailAnnotation.swift'>EmailAnnotation.swift</a></td><td>100%</td><td>100%</td><td>100%</td><td></td></tr><tr><td>&nbsp; &nbsp;<a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/annotations/LengthAnnotation.swift'>LengthAnnotation.swift</a></td><td>100%</td><td>100%</td><td>100%</td><td></td></tr><tr><td>&nbsp; &nbsp;<a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/annotations/LowCaseAnnotation.swift'>LowCaseAnnotation.swift</a></td><td>100%</td><td><b>75%</b></td><td><b>90.91%</b></td><td><a href='https://github.com/fsaldivar-dev/experimental-annotation-swift/blob/undefined/Sources/annotations/LowCaseAnnotation.swift#L20'>20</a></td></tr></tbody></table></details>
Librería que se usa para anidar anotaciones

# Roadmap

| Roadmap | Estado |
| ------------- | ------------- |
| Crear código base | :white_check_mark: |
| SwiftPackage | :white_check_mark: |
| [CocoaPods](https://cocoapods.org) | :white_check_mark: |
| Example | :white_check_mark: |
| UnitTest | :white_check_mark: |
| Documentación  | :rocket:  |
| Extensiones  | [ ]  |


### Swift Package Manager
Swift Package Manager es una herramienta para automatizar la distribución de código Swift y está integrado en el compilador Swift. Está en desarrollo temprano, pero experimental-annotation-swift admite su uso en plataformas compatibles.


Una vez que haya configurado su paquete Swift, agregar experimental-annotation-swift como dependencia es tan fácil como agregarlo al valor de dependencias de su Package.swift.
```swift
dependencies: [
    .package(url: "https://github.com/JavierSaldivarRubio/esperimental-annotation-swift", .upToNextMajor(from: "0.0.1"))
]
```

### CocoaPods
[CocoaPods](https://cocoapods.org) es un administrador de dependencias para proyectos Cocoa. Para obtener instrucciones de uso e instalación, visite su sitio web. Para integrar AnnotationSwift en su proyecto Xcode usando CocoaPods, especifíquelo en su `Podfile`:


```ruby
pod 'AnnotationSwift'
```



### Teoría
En java se conoce ya desde hace mucho tiempo las funciones denominadas anotaciones las cuales son muy comunes en sprint, o al usar la serialización con gson en android, en iOS no existía si no hace pocos años el uso de [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID617)


Si bien es muy similar a las anotaciones de java, aun son muy simples y su principal limitante es que no se puede usar más de una anotación en una variable, 


```swift
@Upercase
@MaxLenght(10) //(X) Error Property type 'String?' does not match that of the 'wrappedValue' property of its wrapper type 'Email'
var name: String?
```
la intención de esta librería es poder crear grupos de annotaciones para cualquier fin.
 Ejemplo:
```swift

struct Model {
    @GroupSet(Email<String>(),
              LowCase<String>())
    var email: String?
    @GroupSet(MinLength<String>(minLength: 3),
              MaxLength<String>(maxLength: 10))
      var min3Max10: String?
}
````
Se puede observar un modelo donde al attributo `email` se le agregan dos restricciones, la primera es que se requiere ser de tipo *email*, la segunda es que necesita que el string sea minusculas, si yo agrego `FSALDIVAR_DEV@example.com` el valor sera cambiado por `fsaldivar_dev@example.com`

