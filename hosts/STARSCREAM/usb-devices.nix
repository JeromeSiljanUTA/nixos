{
  config,
  lib,
  ...
}: let
  devices = [
    {
      name = "Texas Instruments debug probe (for Nest thermostat)";
      vendorId = "0451";
      productId = "d00e";
      mode = "0666";
    }
    {
      name = "Samsung phones in download mode (samloader / Odin)";
      vendorId = "04e8";
      tag = "uaccess";
    }
  ];

  mkRule = device: let
    ids =
      "ATTR{idVendor}==\"${device.vendorId}\""
      + lib.optionalString (device ? productId) ", ATTR{idProduct}==\"${device.productId}\"";
    access =
      if device ? mode
      then ", MODE=\"${device.mode}\""
      else ", TAG+=\"${device.tag or "uaccess"}\"";
  in "# ${device.name}\nSUBSYSTEM==\"usb\", ${ids}${access}";
in {
  services.udev.extraRules = lib.concatMapStringsSep "\n" mkRule devices;
}
