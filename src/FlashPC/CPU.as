package FlashPC
{
    import flash.display.*;
    import flash.utils.ByteArray;
    import flash.desktop.NativeApplication;

    /**
     * Класс ЦП представляет собой виртуальный ЦП для выполнения ассемблерных команд.
     * Он управляет регистрами общего назначения, выполняет команды и взаимодействует с графическим процессором.
     */
    public class CPU extends Sprite
    {
        public var registers:Object = {}; // Processor registers
        private var gpu:GPU; // GPU reference

        private var scriptProcessed:Boolean = false;
        private var isTextSection:Boolean = false;
        private var hasGlobalStart:Boolean = false;
        private var insideFunction:Boolean = false;
        private var currentFunctionName:String = "";
        private var currentFunctionCode:String = "";
        public var asmFunctions:Object = {};

        private var retCommand:Boolean = false;
        /**
         * Конструктор класса ЦП.
         * @param gpu Ссылка на графический процессор для обеспечения взаимодействия.
         */
        public function CPU(gpu:GPU)
        {
            this.gpu = gpu; // Инициализируйте ссылку на графический процессор
            init();
        }

        /**
         * Инициализирует регистры ЦП.
         */
        private function init():void
        {
            // Регистры общего назначения (32 бита)
            registers["eax"] = 0; // EAX - Accumulator Register (регистр аккумулятора)
            registers["ebx"] = 0; // EBX - Base Register (регистр базы)
            registers["ecx"] = 0; // ECX - Count Register (регистр счетчика)
            registers["edx"] = 0; // EDX - Data Register (регистр данных)

            // Указатели и индексы (32 бита)
            registers["esp"] = 0; // ESP - Stack Pointer Register (регистр указателя стека)
            registers["ebp"] = 0; // EBP - Base Pointer Register (регистр указателя базы стека)
            registers["esi"] = 0; // ESI - Source Index Register (регистр индекса источника)
            registers["edi"] = 0; // EDI - Destination Index Register (регистр индекса приемника)

            // 16/8-битные регистры
            registers["ax"] = 0;  // AX - Accumulator Register (регистр аккумулятора - 16 бит)
            registers["ah"] = 0;  // AH - Accumulator High (старший байт регистра аккумулятора)
            registers["al"] = 0;  // AL - Accumulator Low (младший байт регистра аккумулятора)

            registers["bx"] = 0;  // BX - Base Register (регистр базы - 16 бит)
            registers["bh"] = 0;  // BH - Base High (старший байт регистра базы)
            registers["bl"] = 0;  // BL - Base Low (младший байт регистра базы)

            registers["cx"] = 0;  // CX - Count Register (регистр счетчика - 16 бит)
            registers["ch"] = 0;  // CH - Count High (старший байт регистра счетчика)
            registers["cl"] = 0;  // CL - Count Low (младший байт регистра счетчика)

            registers["dx"] = 0;  // DX - Data Register (регистр данных - 16 бит)
            registers["dh"] = 0;  // DH - Data High (старший байт регистра данных)
            registers["dl"] = 0;  // DL - Data Low (младший байт регистра данных)

            // Сегментные регистры (16 бит)
            registers["cs"] = 0;  // CS - Code Segment (сегмент кода)
            registers["ds"] = 0;  // DS - Data Segment (сегмент данных)
            registers["ss"] = 0;  // SS - Stack Segment (сегмент стека)
            registers["es"] = 0;  // ES - Extra Segment (дополнительный сегмент)

            // Флаги состояния (32 бита)
            registers["flags"] = 0; // EFLAGS - Flags Register (регистр флагов состояния)

            // Флаги состояния операций x86 (16-битный режим)
            registers["sf"] = 0; // SF - Sign Flag (регистр флага для проверки после операции на наявность отрицательного результата)
            registers["zf"] = 0; // ZF - Zero Flag (регистр флага для проверки после операции на то что результат являестяь нулём) 
        }

        /**
         * Выполнение команды ассемблера.
         * Поддерживаемые команды: mov, add.
         * @param command Команда ассемблера в виде строки.
        */
        public function executeCommand(command:String):void {
            var parts:Array = command.split(/\s*,\s*|\s+/);
            var operation:String = parts[0];

            switch(operation) {
                case "mov":
                    if (registers.hasOwnProperty(parts[2])) {
                        registers[parts[1]] = registers[parts[2]];
                    }
                    else if (!isNaN(Number(parts[2]))) {
                        registers[parts[1]] = Number(parts[2]);
                    }
                    else {
                        registers[parts[1]] = parts[2];
                    }
                    break;
                case "lea":
                    if (registers.hasOwnProperty(parts[2])) {
                        registers[parts[1]] = registers[parts[2]];
                    }
                    else {
                        registers[parts[1]] = parts[2];
                    }
                    break;

                break;
                case "add":
                    if (isNaN(Number(parts[2]))) {
                        registers[parts[1]] += registers[parts[2]];
                        if (registers[parts[1]] >= 0) {
                            registers["sf"] = 0;
                            if (parts[1] == 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    } else {
                        registers[parts[1]] += Number(parts[2]);
                        if (registers[parts[1]] >= 0) {
                            registers["sf"] = 0;
                            if (parts[1] == 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    }
                    break;
                case "sub":
                    if (isNaN(Number(parts[2]))) {
                        registers[parts[1]] -= registers[parts[2]];
                        if (registers[parts[1]] >= 0) {
                            registers["sf"] = 0;
                            if (parts[1] == 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    } else {
                        registers[parts[1]] -= Number(parts[2]);
                        if (registers[parts[1]] >= 0) {
                            registers["sf"] = 0;
                            if (parts[1] == 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    }
                    break;
                case "cmp":
                    if (isNaN(Number(parts[2]))) {
                        if (registers[parts[1]] - registers[parts[2]] >= 0) {
                            registers["sf"] = 0;
                            if (registers[parts[1]] -= registers[parts[2]] = 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    } else {
                        registers[parts[1]] -= Number(parts[2]);
                        if (registers[parts[1]] - registers[parts[2]] >= 0) {
                            registers["sf"] = 0;
                            if (registers[parts[1]] -= registers[parts[2]] = 0) {
                                registers["zf"] = 1;
                            } else {
                                registers["zf"] = 0;
                            }
                        } else {
                            registers["sf"] = 1;
                        }
                    }
                    break;
                case "mul":
                    registers[parts[1]] *= registers["eax"];
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "div":
                    registers[parts[1]] /= registers["eax"];
                    registers[parts[1]] = Math.round(Number(registers[parts[1]]));
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "div":
                    registers[parts[1]] /= registers["eax"];
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "int":
                    if (parts[1] == "20h") {
                        trace("DOS Служба int 20h - Закрытие програмы");
                        NativeApplication.nativeApplication.exit();
                    } else if (parts[1] == "21h") {
                        handleInt21h();
                    } else {
                        trace("Unsupported interrupt: " + parts[1]);
                    }
                    break;
                case "call":
                    if (asmFunctions[parts[1]] && hasGlobalStart) {
                        for each (var code1:String in asmFunctions[parts[1]].split("\n")) {
                            code1 = code1.replace(/^\s+|\s+$/g, "");

                            if (code1 != "") {
                                executeCommand(code1);
                            }
                        }
                    }
                    break;
                case "loop":
                    if (registers["cx"] != 0 && asmFunctions[parts[1]] && hasGlobalStart) {
                        for(registers["cx"]; registers["cx"] != 0; registers["cx"]--){
                            if(retCommand){
                                retCommand = false;
                                break;
                            }
                            for each (var code2:String in asmFunctions[parts[1]].split("\n")) {
                                code2 = code2.replace(/^\s+|\s+$/g, "");

                                if (code2 != "") {
                                    executeCommand(code2);
                                }
                            }
                        }
                    }
                    break;
                case "loope":
                    if (registers["cx"] != 0 && registers["zf"] != 0 &&asmFunctions[parts[1]] && hasGlobalStart) {
                        if(retCommand){
                            retCommand = false;
                            break;
                        }
                        for(registers["cx"]; registers["cx"] != 0 && registers["zf"] == 1; registers["cx"]--){
                            for each (var code3:String in asmFunctions[parts[1]].split("\n")) {
                                code3 = code3.replace(/^\s+|\s+$/g, "");

                                if (code3 != "") {
                                    executeCommand(code3);
                                }
                            }
                        }
                    }
                    break;
                case "loopz":
                    if (registers["cx"] != 0 && registers["zf"] != 0 &&asmFunctions[parts[1]] && hasGlobalStart) {
                        if(retCommand){
                            retCommand = false;
                            break;
                        }
                        for(registers["cx"]; registers["cx"] != 0 && registers["zf"] == 1; registers["cx"]--){
                            for each (var code4:String in asmFunctions[parts[1]].split("\n")) {
                                code4 = code4.replace(/^\s+|\s+$/g, "");

                                if (code4 != "") {
                                    executeCommand(code4);
                                }
                            }
                        }
                    }
                    break;
                case "loope":
                    if (registers["cx"] != 0 && registers["zf"] != 1 &&asmFunctions[parts[1]] && hasGlobalStart) {
                        if(retCommand){
                            retCommand = false;
                            break;
                        }
                        for(registers["cx"]; registers["cx"] != 0 && registers["zf"] == 0; registers["cx"]--){
                            for each (var code5:String in asmFunctions[parts[1]].split("\n")) {
                                code5 = code5.replace(/^\s+|\s+$/g, "");

                                if (code5 != "") {
                                    executeCommand(code5);
                                }
                            }
                        }
                    }
                    break;
                case "loopz":
                    if (registers["cx"] != 0 && registers["zf"] != 1 &&asmFunctions[parts[1]] && hasGlobalStart) {
                        if(retCommand){
                            retCommand = false;
                            break;
                        }
                        for(registers["cx"]; registers["cx"] != 0 && registers["zf"] == 0; registers["cx"]--){
                            for each (var code6:String in asmFunctions[parts[1]].split("\n")) {
                                code6 = code6.replace(/^\s+|\s+$/g, "");

                                if (code6 != "") {
                                    executeCommand(code4);
                                }
                            }
                        }
                    }
                    break;
                case "dec":
                    registers[parts[1]] -= 1;
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "inc":
                    registers[parts[1]] += 1;
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "idiv":
                    registers[parts[1]] /= registers["eax"];
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "imul":
                    registers[parts[1]] *= registers[parts[2]];
                    if (registers[parts[1]] >= 0) {
                        registers["sf"] = 0;
                        if (parts[1] == 0) {
                            registers["zf"] = 1;
                        } else {
                            registers["zf"] = 0;
                        }
                    } else {
                        registers["sf"] = 1;
                    }
                    break;
                case "neg":
                    registers[parts[1]] *= -1;
                    registers["sf"] = 1;
                    break;
                case "nop":
                    trace("команда NOP - взлом это плохло >:(");
                    break;
                case "ret":
                    retCommand = true;
                    break;
                case "hlt":
                    NativeApplication.nativeApplication.exit();
                    break;
                case "xchg":
                    if (registers.hasOwnProperty(parts[1]) && registers.hasOwnProperty(parts[2])) {
                        var temp:String = registers[parts[1]];
                        registers[parts[1]] = registers[parts[2]];
                        registers[parts[2]] = temp;
                    }
                    break;
                default:
                    trace("Unsupported operation: " + operation);
                    break;
            }
        }

        /**
         * начало выполнения кода
         */
        public function loadAndExecuteScript(script:String):void {
            var scriptLines:Array = script.split("\n");

            for each (var line:String in scriptLines) {
                line = line.replace(/^\s+|\s+$/g, "");

                if (line != "") {
                    if (line.indexOf("section .text") == 0) {
                        isTextSection = true;
                    } else if (line.indexOf("section .data") == 0) {
                        isTextSection = false;
                    } else {
                        if (isTextSection) {
                            processTextSection(line);
                        } else {
                            processDataDeclaration(line);
                        }
                    }
                }
            }

            scriptProcessed = true;

            if (!hasGlobalStart) {
                trace("Error: creation of the _start function is not specified");
                NativeApplication.nativeApplication.exit();
            }

            for (var functionName:String in asmFunctions) {
                if (functionName != "_start") {
                    processFunctionCode(asmFunctions[functionName]);
                    asmFunctions[functionName].split("]").join("");
                }
            }

            for (var funcName:String in asmFunctions) {
                var functionCode:String = asmFunctions[funcName].split("]").join("");
                asmFunctions[funcName] = functionCode;
            }

            if (asmFunctions["_start"] && hasGlobalStart) {
                var startFunctionCode:String = asmFunctions["_start"];
                var startFunctionLines:Array = startFunctionCode.split("\n");

                for each (var code:String in startFunctionLines) {
                    code = code.replace(/^\s+|\s+$/g, "");

                    if (code != "") {
                        executeCommand(code);
                    }
                }
            } else {
                trace("Error: _start function not found");     
                NativeApplication.nativeApplication.exit(); 
            }
        }

        /**
         * работа с функцией _start
         */
        private function processTextSection(textSection:String):void {
            var commentIndex:int = textSection.indexOf(";");
            if (commentIndex != -1) {
                textSection = textSection.substr(0, commentIndex);
            }

            textSection = textSection.replace(/^\s+|\s+$/g, "");

            if (textSection.indexOf("global _start") == 0) {
                hasGlobalStart = true;
            } else if (textSection.indexOf("_start[") != -1) {
                insideFunction = true;
                currentFunctionName = "_start";
                currentFunctionCode = "";
            } else if (insideFunction) {
                currentFunctionCode += textSection + "\n";
                if (textSection.indexOf("]") != -1) {
                    insideFunction = false;
                    var functionName:String = extractFunctionName(currentFunctionName);
                    asmFunctions[functionName] = currentFunctionCode;
                }
            } else if (textSection.indexOf("[") != -1) {
                insideFunction = true;

                currentFunctionName = extractFunctionName(textSection);
                currentFunctionCode = "";
            }
        }

        private function extractFunctionName(functionDeclaration:String):String {
            var index:int = functionDeclaration.indexOf("[");
            
            if (index != -1) {
                var extracted:String = functionDeclaration.substring(0, index);
                return extracted;
            } else {
                return functionDeclaration;
            }
        }

        private function processFunctionCode(functionCode:String):void {
            functionCode = functionCode.split("]").join("");
        }

        /**
         * Управляет выполнением прерываний INT 21h (службы DOS).
        */
        private function handleInt21h():void {
            if (registers["ah"] == 0) {
                trace("DOS Служба 00h - Закрытие програмы");
                NativeApplication.nativeApplication.exit();
            } else if (registers["ah"] == 9) {
                trace("DOS Служба 09h - Вывод строки: " + registers["edx"]);
            } else if (registers["ah"] == "4Ch") {
                trace("DOS Служба 4Ch - Закрытие програмы");
                NativeApplication.nativeApplication.exit();
            } else {
                trace("Неподдерживаемая DOS-служба: " + registers["ah"]);
            }
        }

        /**
         * Обработка объявления данных в секции .data.
         * @param dataDeclaration Строка с объявлением данных.
         */
        private function processDataDeclaration(dataDeclaration:String):void {
            var declarationWithoutComments:String = dataDeclaration.replace(/;.*$/gm, "");

            var parts:Array = declarationWithoutComments.split(/\s+/);

            parts = parts.filter(function(item:String, index:int, array:Array):Boolean {
                return item.length > 0;
            });

            var index:int = parts.indexOf("db");
            if (index == -1) {
                index = parts.indexOf("dd");
            }
            if (index == -1) {
                index = parts.indexOf("dw");
            }
            if (index == -1) {
                index = parts.indexOf("align");
            }

            if (index !== -1) {
                var variableName:String = parts[index - 1];

                var value:* = null;
                var valueString:String = parts.slice(index + 1).join(" ");

                if (valueString.charAt(0) === "'" && valueString.charAt(valueString.length - 1) === "'") {
                    value = valueString.substring(1, valueString.length - 1); 
                } else if (!isNaN(Number(valueString))) {
                    value = Number(valueString);
                } else if (valueString.indexOf(',') !== -1 && (parts[index] === 'db' || parts[index] === 'dw' || parts[index] === 'dd')) {
                    var arrayValues:Array = valueString.split(',');
                    arrayValues = arrayValues.map(function(element:String, index:int, array:Array):* {
                        if (element.charAt(0) === "'" && element.charAt(element.length - 1) === "'") {
                            return element.substring(1, element.length - 1);
                        } else if (!isNaN(Number(element))) {
                            return Number(element);
                        } else {
                            return element;
                        }
                    });
                    value = arrayValues;
                } else {
                    trace("Variable " + variableName + " is of unsupported type. Value: " + valueString);
                }

                registers[variableName] = value;
            }
        }
    }
}
