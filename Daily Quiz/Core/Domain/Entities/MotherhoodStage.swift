import Foundation

enum MotherhoodStage: String, CaseIterable, Identifiable {
    case ttc = "Trying to Conceive"
    case pregnant = "Pregnant"
    case postpartum = "Postpartum"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .ttc:
            return "For women who are planning to get pregnant"
        case .pregnant:
            return "For expectant mothers"
        case .postpartum:
            return "For mothers who have recently given birth"
        }
    }
} 