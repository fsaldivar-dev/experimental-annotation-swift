//
//  PropertyDecorationTests.swift
//  AnnotationSwiftTests
//

import AnnotationSwift
import Testing

@Suite("Decoradores de propiedad")
struct PropertyDecorationTests {

    @Test("El valor por defecto atraviesa la cadena")
    func defaultValue() {
        let user = User()
        #expect(user.email == "paco@mail.com")
        #expect(user.progress == 100)
        #expect(user.contact == nil)
    }

    @Test("Cada asignación atraviesa la cadena en orden")
    func assignment() {
        var user = User()
        user.email = "  OTRO@Mail.COM "
        #expect(user.email == "otro@mail.com")
        user.progress = -5
        #expect(user.progress == 0)
        user.progress = 50
        #expect(user.progress == 50)
    }

    @Test("El inicializador memberwise sigue existiendo y también decora")
    func memberwise() {
        let user = User(email: " A@B.CO ", progress: 300, contact: "a@b.co", reversedOrder: " X ")
        #expect(user.email == "a@b.co")
        #expect(user.progress == 100)
        #expect(user.contact == "a@b.co")
        #expect(user.reversedOrder == "x")
    }

    @Test("Un decorador puede rechazar el valor (Email → nil)")
    func rejection() {
        var user = User()
        user.contact = "paco@mail.com"
        #expect(user.contact == "paco@mail.com")
        user.contact = "no es un correo"
        #expect(user.contact == nil)
    }

    @Test("Un decorador genérico infiere su tipo de la propiedad")
    func genericDecorator() {
        let settings = Settings(volume: 3)
        #expect(settings.volume == 1.0)
        settings.volume = -1
        #expect(settings.volume == 0.0)
        settings.volume = 0.5
        #expect(settings.volume == 0.5)
    }
}
