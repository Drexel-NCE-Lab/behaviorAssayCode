%Script to transfer the image files from the specified source folder to the
%specified destination, extracting and processing the timestamp metadata in
%the process
function transferTemporaryFiles(memDataLocations,rawImageList)
scriptBasePath = fileparts(mfilename('fullpath'));
if ~exist('memDataLocations','var')
    memDataLocations = [scriptBasePath '/memDataLocations.mat'];
end
if ~exist('rawImageList','var')
    rawImageList = [scriptBasePath '/rawImageListing.mat'];
end
% global rawImageLocationListing dataLocations;
LS = load(rawImageList);
rawImageLocationListing = LS.rawImageLocationListing;
LS = load(memDataLocations);
dataLocations = LS.dataLocations;

try
    transferMemFiles();
    convertTemporaryFiles();
    %system([scriptBasePath '/push_data_archive.bat']);
catch ME
    save(memDataLocations,'dataLocations');
    save(rawImageList,'rawImageLocationListing');
    rethrow(ME);
end
save(memDataLocations,'dataLocations');
save(rawImageList,'rawImageLocationListing');
    function transferMemFiles()
        disp('Transfering memory files to temporary storage:');
        sweepCount = numel(dataLocations);
        n = 0;
        while ~isempty(dataLocations)
            n = n+1;
            tmpLocation = dataLocations{1}{1};
            folderName = regexpi(tmpLocation,'D:[/\\]+(.*)','tokens');
            hdLocation = ['C:/Data/' folderName{1}{1}];
            location = [dataLocations{1}{2}];
            mkdir(hdLocation);
            movefile([tmpLocation '/tmp/*'],hdLocation);
            rawImageLocationListing{end+1,:} = [{hdLocation},{location}];
            rmdir(tmpLocation,'s');
            dataLocations(1) = [];
            fprintf('Completed %d of %d...\n',n,sweepCount);
        end
    end

    function convertTemporaryFiles()
        fprintf('Beginning image conversion. %d folders in queue.\n',length(rawImageLocationListing));
        while ~isempty(rawImageLocationListing)
            if exist(rawImageLocationListing{1}{1},'dir')
                fprintf('Converting images in folder: %s\n',rawImageLocationListing{1}{1})
                processTrialImageStack(rawImageLocationListing{1}{1},rawImageLocationListing{1}{2})
                fprintf('Completed image conversion. %d folders remain in queue.\n',length(rawImageLocationListing)-1);
            else
                throw(MException('NoFolder:rawImageLocation','Image folder %s not found',rawImageLocationListing{1}{1}));
            end
            rawImageLocationListing(1,:) = [];
        end
    end
end

