import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_project/data/project_master_dto.dart';
import 'package:algo_erp_front/features/organization_project/domain/project_master.dart';

class ProjectMasterMapper implements Mapper<ProjectMasterDto, ProjectMaster> {
  const ProjectMasterMapper();

  @override
  ProjectMaster toEntity(ProjectMasterDto dto) => ProjectMaster(
    id: dto.id,
    projectId: dto.projectId,
    name: dto.projectName,
    projectCode: dto.projectCode,
    parentProjectMasterId: dto.parentProjectMasterId,
    projectOwnerContactId: dto.projectOwnerContactId,
    associatedLedgerId: dto.associatedLedgerId,
    godownId: dto.godownId,
    coordinatorEmployeeId: dto.coordinatorEmployeeId,
    description: dto.projectDescription,
    status: dto.projectStatus,
    startDate: dto.startDate,
    endDate: dto.endDate,
    estimatedValue: dto.estimatedValue,
    location: dto.location,
    detail: dto.detail,
  );

  @override
  ProjectMasterDto toDto(ProjectMaster entity) => ProjectMasterDto(
    id: entity.id,
    projectId: entity.projectId,
    projectName: entity.name,
    projectCode: entity.projectCode,
    parentProjectMasterId: entity.parentProjectMasterId,
    projectOwnerContactId: entity.projectOwnerContactId,
    associatedLedgerId: entity.associatedLedgerId,
    godownId: entity.godownId,
    coordinatorEmployeeId: entity.coordinatorEmployeeId,
    projectDescription: entity.description,
    projectStatus: entity.status,
    startDate: entity.startDate,
    endDate: entity.endDate,
    estimatedValue: entity.estimatedValue,
    location: entity.location,
    detail: entity.detail,
  );
}
