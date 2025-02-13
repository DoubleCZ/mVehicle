import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';
import { fetchNui } from './fetchNui';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { isEnvBrowser } from './misc';

interface Lang { [key: string]: string; }

interface LangData {
    [key: string]: string;
}

const DevLang: LangData = {
    "Trailer Target": "",
    "flip_trailer": "Flip Trailer",
    "up_dow_ramp": "Raise/Lower Ramp",
    "up_dow_platform": "Raise/Lower Platform",
    "attach_vehicle": "Attach Vehicle",
    "dettach_vehicle": "Detach Vehicle",

    "Vehicle doors": "",
    "open_door": "Open Door",
    "close_door": "Close Door",

    "Keys": "",
    "key_string": "License Plate: %s",
    "key_targetdoors": "Open / Close Doors",

    "GiveCar Command": "",
    "givecar_noty": "You are now the owner of this vehicle %s",
    "givecar_help": "Give a vehicle to a player with multiple options.",
    "givecar_playerveh ": "Set the vehicle the player is in as owned",
    "givecar_yes": "Yes",
    "givecar_no": "No",
    "givecar_menu1": "Vehicle Model",
    "givecar_menu2": "Garage",
    "givecar_menu3": "Temporary Vehicle?",
    "givecar_menu4": "Date",
    "givecar_menu5": "Hour",
    "givecar_menu6": "Minutes",
    "givecar_menu7": "Vehicle Color 1",
    "givecar_menu8": "Vehicle Color 2",
    "givecar_menu9": "Vehicle Job",
    "givecar_menu810": "Leave blank for no JOB",

    "carkeyMenu": "",
    "carkey_menu1": "Personal Vehicles",
    "carkey_menu2": "You have no vehicles.",
    "carkey_menu3": "Give Key",
    "carkey_menu4": "Add keys to a player by their ID.",
    "carkey_menu5": "Nobody has keys to this vehicle 😪",
    "carkey_menu6": "Delete",
    "carkey_menu7": "Change name",
    "carkey_menu8": "Mark GPS",
    "Fake Plate": "",
    "fakeplate1": "Fake Plate",
    "fakeplate2": "This vehicle is not owned by you...",
    "fakeplate3": "Original Plate",
    "fakeplate4": "Changing plate"

};




const LangContext = createContext<Lang>(DevLang);

export const LangProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [lang, setLang] = useState<Lang>(DevLang);

    useNuiEvent<Lang>('ui:Lang', (data) => {
        setLang(data);
    });

    useEffect(() => {
        if (isEnvBrowser()) {
            setLang(DevLang);
        } else {
            fetchNui<Lang>('ui:Lang')
                .then(data => {
                    setLang(data);
                })
                .catch(error => {
                    console.error('Error fetching language data:', error);
                });
        }
    }, []);

    const value = useMemo(() => lang, [lang]);

    return (
        <LangContext.Provider value={value}>
            {children}
        </LangContext.Provider>
    );
};

export const useLang = () => {
    return useContext(LangContext);
};