classdef dataStorage < handle
    properties
        controller
        dataLocations
        missedTrials
        subjectFolder
        jobHandle
        scriptBasePath
        dataList
        debugOn
    end
    methods
        function obj = dataStorage()
            obj.controller = [];
            obj.dataLocations = {};
            obj.missedTrials = [];
            obj.subjectFolder = [];
            obj.jobHandle = [];
            obj.scriptBasePath = [];
            obj.dataList = [];
            obj.debugOn = [];
        end
    end
end