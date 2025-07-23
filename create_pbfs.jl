using ArgParse, PedTransitAccess

function main()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "infile"
            help = "Input file"
        "baseout"
            help = "Output file, baseline"
    end

    args = parse_args(s)

    create_pbfs(args["infile"], args["baseout"], nothing, nothing, nothing)
end

main()