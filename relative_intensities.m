%function relative_intensities(number_of_strips, reference_strip_number)
number_of_strips = 4;
reference_column_number = 4;


cropped_image = imread('cropped.png');
cropped_image = im2gray(cropped_image);

number_of_pixel_rows = size(cropped_image,1);
number_of_pixel_columns = size(cropped_image,2);


%cut image into strips
strip_pixel_columns = floor(number_of_pixel_columns / number_of_strips);

strips = zeros(number_of_strips, number_of_pixel_rows, strip_pixel_columns);
for strip_index = 1:number_of_strips
    
    start_column = (strip_index-1) * strip_pixel_columns + 1;
    end_column = strip_index*strip_pixel_columns;
    
    strips(strip_index,:,:) = cropped_image(:,start_column:end_column);
    
end

figure(1);
for strip_index = 1:number_of_strips
    subplot(1,number_of_strips,strip_index);
    imshow(squeeze(strips(strip_index,:,:)),[]);
    if strip_index == reference_column_number
        title('reference column');
    end
end
suptitle('cut image');

%use horizontal median to remove curved portion of strip and padding
horizontal_filtered_strips = zeros(number_of_strips, number_of_pixel_rows, strip_pixel_columns);
for strip_index = 1:number_of_strips
    for row = 1:number_of_pixel_rows
        horizontal_filtered_strips(strip_index,row,:) = median(squeeze(strips(strip_index,row,:)));
    end
end

figure(2);
for strip_index = 1:number_of_strips
    subplot(1,number_of_strips,strip_index);
    imshow(squeeze(horizontal_filtered_strips(strip_index,:,:)),[]);
    if strip_index == reference_column_number
        title('reference column');
    end
end
suptitle('median filtered strips');

%adaptive vertical histogram equalization to separate vertically
figure(3);
vertical_filtered_strips = zeros(number_of_strips, number_of_pixel_rows, strip_pixel_columns);
for strip_index = 1:number_of_strips
    strip = squeeze(horizontal_filtered_strips(strip_index,:,:));
    derivative = strip(2:end,1)-strip(1:end-1,1);
    
    vertical_filtered_strip = zeros(number_of_pixel_rows,strip_pixel_columns);
    
    band_index = 0;
    band_on = 0;
    derivative_threshold = 10;
    for row = 10:number_of_pixel_rows-10%pad by 10 to avoid edge effects
        if derivative(row)>derivative_threshold && ~band_on
            band_on = 1;
            band_index = band_index + 1;
        elseif derivative(row)<-1*derivative_threshold && band_on
            band_on = 0;
        end
        if band_on
            vertical_filtered_strip(row,:) = band_index;
        end
    end
    vertical_filtered_strips(strip_index,:,:) = vertical_filtered_strip;
end

figure(3);
for strip_index = 1:number_of_strips
    subplot(1,number_of_strips,strip_index);
    imshow(squeeze(vertical_filtered_strips(strip_index,:,:)>0),[]);
    if strip_index == reference_column_number
        title('reference column');
    end
end
suptitle('band filtered strips');

figure(4);
reference_strip = squeeze(strips(reference_column_number,:,:));
vertical_filtered_reference = squeeze(vertical_filtered_strips(reference_column_number,:,:));
for strip_index = 1:number_of_strips
    
    
    if strip_index ~= reference_column_number
        subplot(1,4,1);
        strip = squeeze(strips(strip_index,:,:));
        imshow(strip,[]);
        title('strip')
        band_index = 1;
        vertical_filtered_strip = squeeze(vertical_filtered_strips(strip_index,:,:));
        mask1 = vertical_filtered_strip == band_index;
        while any(mask1)
            subplot(1,4,2);
            imshow(mask1.*strip,[]);
            title(['strip ',num2str(strip_index),', band ',num2str(band_index)]);
            integral = sum(sum(mask1.*strip));
            xlabel(num2str(integral));
            %find reference mask
            mask1_rows = mask1(:,1);
            found = 0;
            for row = find(mask1_rows,1,'last'):-1:1
                if vertical_filtered_reference(row,1) > 0
                    reference_band = vertical_filtered_reference(row,1);
                    found = 1;
                    break;
                end
            end
            subplot(1,4,3);
            imshow(reference_strip,[]);
            title('reference strip');
            if found == 1
                mask2 = vertical_filtered_reference == reference_band;
                subplot(1,4,4);
                imshow(mask2.*reference_strip,[]);
                title(['reference strip, band ',num2str(reference_band)]);
                integral = sum(sum(mask2.*reference_strip));
                xlabel(num2str(integral));
            else
                subplot(1,4,4);
                imshow(zeros(size(strip)),[]);
                title('no reference strip found');
            end
            pause
            
            band_index = band_index + 1;
            mask1 = vertical_filtered_strip == band_index;
        end
    end
end