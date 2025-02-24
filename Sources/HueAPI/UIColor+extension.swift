//
//  UIColor+extension.swift
//
//  Created by Jan Svensson on 2025-02-24.
//

import UIKit

extension UIColor {
    /// Create a UIColor from a kelvin value.
    /// - Parameter temperature: The temperature in kelvin
    convenience init(temperature: CGFloat) {

        /*
            Algorithm taken from Tanner Helland's post
            http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
        */

        let percentKelvin = temperature / 100
        let red, green, blue: CGFloat

        red =   Self.clamp(percentKelvin <= 66 ?
                           255 :
                            (329.698727446 * pow(percentKelvin - 60, -0.1332047592)))
        green = Self.clamp(percentKelvin <= 66 ?
                           (99.4708025861 * log(percentKelvin) - 161.1195681661) :
                            288.1221695283 * pow(percentKelvin - 60, -0.0755148492))
        blue =  Self.clamp(percentKelvin >= 66 ?
                           255 :
                            (percentKelvin <= 19 ?
                             0 :
                             138.5177312231 * log(percentKelvin - 10) - 305.0447927307))

        self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }

    /// Create a UIColor from a mirek value. Convert Philips Hue mirek to kelvin
    /// Reference https://developers.meethue.com/develop/hue-api-v2/core-concepts/#colors-get-more-complicated.
    ///
    /// - Parameter mirek: The mirek value
    convenience init(mirek: Int) {
        if mirek < 153 || mirek > 500 { // This is outside the possible range
            self.init(red: 1, green: 1, blue: 1, alpha: 1)
            return
        }
        
        var temp: CGFloat = 6500 // Kelvin
        let mirekSteps: CGFloat = 500 - 153
        let tempRange: CGFloat = 6500 - 2000
        let unitPerMirek: CGFloat = tempRange / mirekSteps
        
        let mirekStepsToSubtract = CGFloat(mirek) - 153
        temp -= mirekStepsToSubtract * unitPerMirek
        
        self.init(temperature: temp)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        return value > 255 ? 255 : (value < 0 ? 0 : value)
    }
}
