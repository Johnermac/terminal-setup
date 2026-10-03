function tfr --description 'Claude risk review of a terraform plan (tfr [planfile])'
    set -l plan $argv[1]
    set -l tmp

    if test -z "$plan"
        set tmp (mktemp -d)
        set plan $tmp/plan
        if not terraform plan -input=false -out=$plan >&2
            rm -rf $tmp
            return 1
        end
    end

    terraform show -no-color $plan |
        _claude_p sonnet 'Review this Terraform plan for risk. List findings most severe first, one line each, starting with the resource address: destroys and replacements, IAM or resource policy widening, public exposure (0.0.0.0/0, public buckets, public endpoints), encryption or logging turned off, data loss. Skip cosmetic changes. Last line: VERDICT: SAFE, REVIEW or DANGEROUS.'
    set -l st $pipestatus[2]

    test -n "$tmp"; and rm -rf $tmp
    return $st
end
