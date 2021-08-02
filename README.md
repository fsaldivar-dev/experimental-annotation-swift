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


# Teoría
En java se conoce ya desde hace mucho tiempo las funciones denominadas anotaciones las cuales son muy comunes en sprint, o al usar la serialización con gson en android, en iOS no existía si no hace pocos años el uso de [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html)


Si bien es muy similar a las anotaciones de java, aun son muy simples y su principal limitante es que no se puede usar más de una anotación en una variable, 


```swift
@Upercase
@MaxLenght(10) //(X) Error Property type 'String?' does not match that of the 'wrappedValue' property of its wrapper type 'Email'
var name: String?
```
la intención de esta librería es poder crear grupos de annotaciones para cualquier fin.


# Solución
Para solucionar el escenario anterior y con el uso de polimorfismo se definieron varias interfaces
```swift
public protocol Annotation {
    func executeAction(wrappedValue: T?) -> T?
    func initValue(value: T)
}
```
la intencion de la annotación es que cualquier [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html) que necesitemos crear implementen el protocolo de Annotation en donde
```swift
    func executeAction(wrappedValue: T?) -> T?
```
se trate el valor de la propiedad que en el caso anterior se requería que fuera en mayusculas con una longitud de 10 caracteres.
```swift
    func initValue(value: T)
```
mientras que **initValue** inicializa el valor de la propiedad.

## Ejemplo de anotación
```swift
import Foundation
@propertyWrapper
class Email<Value: StringProtocol>: Annotation {
    /// Valor de la propiedad a tratar
    private var value: Value?
    /// Constructor de la anotación
    init(wrappedValue value: Value? = nil) {
        self.wrappedValue = value
    }
    /// envoltorio del valor
    public var wrappedValue: Value? {
        get { return self.value }
        set { self.value = self.executeAction(wrappedValue: newValue) }
    }
    
    /// Valida si el varlor recivido es del mismo tipo que el tipo de la propiedad
    /// para poder iniciar el valor
    func initValue<T>(value: T) {
        guard let value = value as? Value else {
            return
        }
        self.wrappedValue = value
    }
     /// Valida si el varlor recivido es del mismo tipo que el tipo de la propiedad
     /// para poder tratar el valor
    func executeAction<T>(wrappedValue: T?) -> T? {
        guard let stringValue = wrappedValue as? Value else {
            return wrappedValue
        }
        return (self.validate(email: stringValue) ? stringValue : nil ) as? T
    }
    /// valida si el valor que se recibe es de tipo email
    private func validate(email: Value?) -> Bool {
        guard let email = email else { return false }
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-za-z]{2,64}"
        let pred = NSPredicate(format: "SELF MATCHES %@", regex)
        return pred.evaluate(with: email)
    }
}
```
En esté [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html) se valida si el valor asignado es un email, si no lo es el valor asignado sera **nil**


Y como vemos, se hizo el uso de las funciones **executeAction** e **initValue**


De esta forma podremos agrupar anotaciones de la siguiente forma
## Ejemplo de Grupo de anotaciones
```swift
struct Model {
    @GroupSet(Email(),
              LowCase())
    var email: String?
    @GroupSet(MinLength(minLength: 3),
              MaxLength(maxLength: 10))
    var name: String?
    @LowCase
    var userName: String?
}
```


En el ejemplo se crea un modelo donde tiene las propiedades de email, name y userName dando las siguientes condiciones

**email:** *Se requiere que el valor sea un correo electrónico y el valor este en minúsculas*

**name:** *Se requiere que el valor sea un nombre con una longitud mínima de 3 y máxima de 10*

**userName:** *Se requiere que el valor sea un nombre de usuario en minúsculas*


Como se observa, las propiedades pueden tener una o más reglas, de está forma se pueden agregar varias reglas para un modelo, pero esta funcionalidad no esta limitada a solo validaciones, se puede usar en anotaciones como las de Resolver @Injection o cualquier otra que no se limite solo a validaciones del modelo.
