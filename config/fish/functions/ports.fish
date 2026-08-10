function ports --description 'Listening TCP/UDP sockets with owning process'
    if command -q ss
        ss -tulpn
    else
        sudo netstat -tulpn
    end
end
