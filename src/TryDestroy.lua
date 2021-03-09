return function(object: any, method: string?)
    if not object then
        return
    end

    if method then
        object[method](object)
        return
    end

    object:Destroy()
end
