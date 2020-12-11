weapon
{
    name: "PS hooter"
    mag: 20
    reserve: 120
    vmodel: "models/weapons/ray/v_ray.mdl"
    gmodel: "models/weapons/ray/g_ray.mdl"
    ads: '4, 0, 6.5'
    firetype: 1
    pap: 71
    dmg: 1
    shotcount: 2
    bodypen: 2
    penetration: 3
    spread: 3
    fdelay: 0.1
    rdelay: 0.5
    walkspeed: 1
    firesound: "sounds/misc/oof.wav"
    skin: 0
    recoil: 500
    crossmin: 10
    crossmax: 30
    lowmag: 5
    lowreserve: 25
    flash: '0, 0, 0'
    flashsize: 1

    frames
    [
        1
        3
        4
        8
        12
        15
        16
        17
        1
        3
        4
        8
        12
        15
        16
    ]
}

weapon
{
    name: "PS Taker"
    mag: 80
    reserve: 640
    vmodel: "models/weapons/ray/v_ray.mdl"
    gmodel: "models/weapons/ray/g_ray.mdl"
    isdual: 0
    ads: '4, 0, 6.5'
    firetype: 0
    dmg: 64
    shotcount: 5
    bodypen: 5
    penetration: 8
    spread: 2
    fdelay: 0.08
    rdelay: 0.4
    walkspeed: 1.15
    firesound: "sounds/misc/bigOOF.wav"
    skin: 1
    recoil: 0
    crossmin: 5
    crossmax: 20
    lowmag: 20
    lowreserve: 48
    flash: '0, 0, 0'
    flashsize: 1

    frames
    [
        1
        3
        4
        8
        12
        15
        16
        17
        1
        3
        4
        8
        12
        15
        16
    ]

    framesnd
    [
        6
        12
        16
    ]

    snd
    [
        sounds/pu/nuke.wav
        sounds/pu/drop.wav
        sounds/pu/pickup.wav
    ]
}

weapon
{
    name: "PD Erpa"
    mag: 10
    reserve: 80
    vmodel: "models/weapons/panzer/v_panzer.mdl"
    gmodel: "models/weapons/panzer/g_panzer.mdl"
    ads: '4, 0, 6.5'
    firetype: 1
    pap: 73
    dmg: 100
    shotcount: 1
    bodypen: 3
    penetration: 5
    fdelay: 0.2
    rdelay: 0.8
    walkspeed: 0.935
    firesound: "sounds/misc/derp.wav"
    skin: 0
    recoil: 5000
    crossmin: 4
    crossmax: 40
    lowmag: 5
    lowreserve: 15
    flash: '0, 0, 0'
    flashsize: 1

    frames
    [
        1
        3
        4
        8
        12
        15
        16
        17
        1
        3
        4
        8
        12
        15
        16
    ]
}

weapon
{
    name: "PP Raker"
    mag: 80
    reserve: 800
    vmodel: "models/weapons/panzer/v_panzer.mdl"
    vmodel2: "models/weapons/panzer/v_panzer.mdl"
    gmodel: "models/weapons/panzer/g_panzer.mdl"
    isdual: 1
    ads: '4, 0, 6.5'
    firetype: 0
    dmg: 100
    shotcount: 3
    bodypen: 5
    penetration: 8
    spread: 2
    fdelay: 0.1
    rdelay: 0.4
    walkspeed: 1.0
    firesound: "sounds/misc/bigDERP.wav"
    skin: 1
    recoil: 0
    crossmin: 4
    crossmax: 20
    lowmag: 20
    lowreserve: 48
    flash: '0, 0, 0'
    flashsize: 1

    frames
    [
        1
        3
        4
        8
        12
        15
        16
        17
        1
        3
        4
        8
        12
        15
        16
    ]

    framesnd
    [
        6
        12
        16
    ]

    snd
    [
        sounds/pu/nuke.wav
        sounds/pu/drop.wav
        sounds/pu/pickup.wav
    ]
}