{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            implementation =
                                config :
                                    if builtins.typeOf config == "list" then
                                        let
                                            domains = [ "service" "timer" "slice" "path" "socket" "install" "unit" ] ;
                                            mapper = domain : [ { name = "${ domain }s" ; value = units domain ; } ] ;
                                            unit =
                                                type : index :
                                                    let
                                                        u = builtins.elemAt config index ;
                                                        in if builtins.typeOf u == "set" && builtins.hasAttribute "type" u then
                                                            let
                                                                name = builtins.hashString "sha512" ( builtins.toString index ) ;
                                                                in [ { name = name ; value = builtins.getAttr u "type" ; } ]
                                                        else [ ] ;
                                            units = type : builtins.listToAttrs ( builtins.concatLists ( builtins.genList ( unit type ) ( builtins.length config ) ) ) ;
                                            in builtins.listToAttrs ( builtins.concatLists ( builtins.map mapper domains ) )
                                    else builtins.throw "systemd config must be a list" ;
                            in
                                {
                                    check =
                                        {
                                            config ? [ ] ,
                                            coreutils ,
                                            expected ? "49a616a1" ,
                                            mkDerivation ,
                                            writeShellApplication
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase = ''execute-install "$out"'' ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                let
                                                                    observed = implementation config ;
                                                                    in
                                                                        if expected == observed then
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "execute-install" ;
                                                                                    runtimeInputs = [ coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                        '' ;
                                                                                }
                                                                        else
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "execute-install" ;
                                                                                    runtimeInputs = [ coreutils failure ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            touch "$OUT"
                                                                                            failure f7a3ead3 "We expected expected to equal observed"  "EXPECTED=${ builtins.toFile "expected" ( builtins.toJSON expected ) }" "OBSERVED=${ builtins.toFile "observed" ( builtins.toJSON observed ) }"
                                                                                        '' ;
                                                                                }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}